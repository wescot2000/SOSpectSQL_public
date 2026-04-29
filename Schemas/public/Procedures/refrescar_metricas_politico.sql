-- Procedure: public.refrescar_metricas_politico
-- Módulo político: cálculo incremental acumulativo de métricas de desempeño por político.
-- Creado: 2026-03-09 | Rediseñado: 2026-03-10
--
-- ARQUITECTURA HÍBRIDA:
--   1. Fuente de verdad: public.metricas_politico (SCD Tipo 2)
--   2. Caché de lectura: public.mv_metricas_politico (una fila por político, para la API)
--   3. Desglose por tipo: public.mv_metricas_politico_tipos (para la API)
--
-- LÓGICA INCREMENTAL:
--   Por cada político vigente se determina la última fecha procesada (fecha_hasta_alarmas
--   del registro vigente en metricas_politico). Solo se procesan alarmas con
--   fecha_alarma > ese corte. Los resultados se acumulan sobre los totales previos.
--
-- FUENTES DE DATOS:
--   - Alarmas activas:   public.alarmas (con cnt_likes y cnt_reenvios)
--   - Alarmas archivadas: migracion.migra_alarmas (sin cnt_likes / cnt_reenvios)
--   - Geografía:         public.alarmas_territorio (nunca se borra; persiste aunque la alarma archive)
--   - Cierres activos:   public.descripcionesalarmas WHERE flag_es_cierre_alarma = TRUE
--   - Cierres archivados: migracion.migra_descripcionesalarmas WHERE flag_es_cierre_alarma = TRUE
--
-- LLAMADA MANUAL (primera carga o re-procesamiento):
--   CALL public.refrescar_metricas_politico();
--
-- CRON DIARIO A LAS 0:00 UTC:
--   SELECT cron.schedule('Metricas politicos', '0 0 * * *', 'CALL public.refrescar_metricas_politico()');
--
-- NOTA: CONCURRENTLY ya NO aplica (mv_metricas_politico ya no es MV).
--   El índice idx_mv_metricas_politico_pk se reemplazó por la constraint UNIQUE del CREATE TABLE.

CREATE OR REPLACE PROCEDURE public.refrescar_metricas_politico()
LANGUAGE plpgsql
AS $$
DECLARE
    rec_politico          RECORD;    -- político vigente en iteración
    rec_anterior          RECORD;    -- registro vigente en metricas_politico (puede ser NULL)
    v_anterior_encontrado BOOLEAN;   -- TRUE si SELECT INTO encontró fila; evita ambigüedad de rec IS NULL en PL/pgSQL
    v_fecha_corte         TIMESTAMPTZ;
    v_ahora               TIMESTAMPTZ := NOW();

    -- Delta (solo alarmas nuevas desde fecha_corte)
    v_delta_total             INTEGER;
    v_delta_cerradas          INTEGER;
    v_delta_likes             INTEGER;
    v_delta_reenvios          INTEGER;
    v_delta_sum_dias          NUMERIC;
    v_delta_cnt_cierres       INTEGER;

    -- Acumulados finales
    v_cnt_total               INTEGER;
    v_cnt_abiertas            INTEGER;
    v_cnt_cerradas            INTEGER;
    v_pct_resolucion          NUMERIC(5,1);
    v_cnt_likes               INTEGER;
    v_cnt_reenvios            INTEGER;
    v_avg_dias                NUMERIC(8,1);
    v_cnt_cierres_con_fecha   INTEGER;
    v_tipos_alarma            JSONB;
    v_fecha_desde             TIMESTAMPTZ;

    -- Aprobación ciudadana (calificación 1-5 escalada a 0-100%)
    v_pct_aprobacion          NUMERIC(5,1);
    v_cnt_votantes_aprobacion INTEGER;

    -- Score de gestión (0–100)
    -- = pct_resolucion (historial) - penalizacion (alarmas abiertas hoy × días × viralidad)
    v_score_gestion           NUMERIC(5,1);
    v_score_base              NUMERIC;
    v_penalizacion_bruta      NUMERIC;
    v_penalizacion            NUMERIC;

BEGIN

    -- ══════════════════════════════════════════════════════════════════════════
    -- Iterar sobre cada político con vigencia activa
    -- ══════════════════════════════════════════════════════════════════════════
    FOR rec_politico IN
        SELECT DISTINCT v.politico_id
        FROM public.pol_vigencias v
        WHERE v.activo = TRUE
          AND CURRENT_DATE BETWEEN v.fecha_inicio AND COALESCE(v.fecha_fin, 'infinity'::date)
    LOOP

        -- ── 1. Leer registro vigente en metricas_politico ────────────────────
        SELECT *
          INTO rec_anterior
          FROM public.metricas_politico
         WHERE politico_id = rec_politico.politico_id
           AND fecha_fin_vigencia IS NULL;
        v_anterior_encontrado := FOUND;   -- guardar ANTES de cualquier otro SQL

        IF NOT v_anterior_encontrado THEN
            -- Primera vez: procesar toda la historia disponible
            v_fecha_corte := TIMESTAMPTZ '1900-01-01 00:00:00+00';
        ELSE
            v_fecha_corte := rec_anterior.fecha_hasta_alarmas;
        END IF;

        -- ── 2. Calcular delta (alarmas nuevas desde fecha_corte) ─────────────
        -- Fuente DUAL: activas (public.alarmas) + archivadas (migracion.migra_alarmas)
        -- La geografía se resuelve siempre desde public.alarmas_territorio (nunca se borra).
        -- NOTA: migra_alarmas no tiene cnt_likes/cnt_reenvios; se asumen 0 para archivadas.
        WITH

        -- Territorios del político vigente (igual lógica que la MV original)
        pv AS (
            SELECT v.politico_id, v.territorio_id, NULL::CHAR(2) AS pais_id, pt.nivel
            FROM public.pol_vigencias v
            JOIN public.pol_territorios pt ON pt.territorio_id = v.territorio_id
            WHERE v.activo = TRUE
              AND v.territorio_id IS NOT NULL
              AND CURRENT_DATE BETWEEN v.fecha_inicio AND COALESCE(v.fecha_fin, 'infinity'::date)
              AND v.politico_id = rec_politico.politico_id

            UNION ALL

            SELECT v.politico_id, NULL::INTEGER, v.pais_id, 'PAIS'
            FROM public.pol_vigencias v
            WHERE v.activo = TRUE
              AND v.pais_id IS NOT NULL
              AND CURRENT_DATE BETWEEN v.fecha_inicio AND COALESCE(v.fecha_fin, 'infinity'::date)
              AND v.politico_id = rec_politico.politico_id
        ),

        -- Alarmas activas en el delta (tienen cnt_likes y cnt_reenvios)
        alarmas_activas_delta AS (
            SELECT a.alarma_id, a.estado_alarma, a.fecha_alarma,
                   COALESCE(a.cnt_likes, 0)    AS cnt_likes,
                   COALESCE(a.cnt_reenvios, 0) AS cnt_reenvios,
                   a.tipoalarma_id
            FROM public.alarmas a
            WHERE a.fecha_alarma > v_fecha_corte
        ),

        -- Alarmas archivadas en el delta (sin cnt_likes/cnt_reenvios)
        alarmas_archivadas_delta AS (
            SELECT ma.alarma_id, ma.estado_alarma, ma.fecha_alarma,
                   0 AS cnt_likes,
                   0 AS cnt_reenvios,
                   ma.tipoalarma_id
            FROM migracion.migra_alarmas ma
            WHERE ma.fecha_alarma > v_fecha_corte
        ),

        -- Unión de ambas fuentes
        todas_alarmas_delta AS (
            SELECT alarma_id, estado_alarma, fecha_alarma, cnt_likes, cnt_reenvios, tipoalarma_id
            FROM alarmas_activas_delta
            UNION ALL
            SELECT alarma_id, estado_alarma, fecha_alarma, cnt_likes, cnt_reenvios, tipoalarma_id
            FROM alarmas_archivadas_delta
        ),

        -- Filtrar las alarmas del delta que corresponden a este político
        -- (usando alarmas_territorio, que nunca se borra)
        alarmas_del_politico AS (

            -- DISTRITO
            SELECT tad.alarma_id, tad.estado_alarma, tad.fecha_alarma,
                   tad.cnt_likes, tad.cnt_reenvios, tad.tipoalarma_id
            FROM pv
            JOIN public.pol_homologacion_google hg
                ON hg.territorio_id = pv.territorio_id
                AND hg.nivel_google = 'barrio'
                AND hg.activo = TRUE
            JOIN public.alarmas_territorio at
                ON at.barrio_normalizado = hg.nombre_google_normalizado
            JOIN todas_alarmas_delta tad ON tad.alarma_id = at.alarma_id
            WHERE pv.nivel = 'DISTRITO'

            UNION ALL

            -- CIUDAD
            SELECT tad.alarma_id, tad.estado_alarma, tad.fecha_alarma,
                   tad.cnt_likes, tad.cnt_reenvios, tad.tipoalarma_id
            FROM pv
            JOIN public.pol_homologacion_google hg
                ON hg.territorio_id = pv.territorio_id
                AND hg.nivel_google = 'ciudad'
                AND hg.activo = TRUE
            JOIN public.alarmas_territorio at
                ON at.ciudad_normalizada = hg.nombre_google_normalizado
            JOIN todas_alarmas_delta tad ON tad.alarma_id = at.alarma_id
            WHERE pv.nivel = 'CIUDAD'

            UNION ALL

            -- REGION
            SELECT tad.alarma_id, tad.estado_alarma, tad.fecha_alarma,
                   tad.cnt_likes, tad.cnt_reenvios, tad.tipoalarma_id
            FROM pv
            JOIN public.pol_territorios pt_ciudad
                ON pt_ciudad.parent_id = pv.territorio_id
                AND pt_ciudad.nivel = 'CIUDAD'
            JOIN public.pol_homologacion_google hg
                ON hg.territorio_id = pt_ciudad.territorio_id
                AND hg.nivel_google = 'ciudad'
                AND hg.activo = TRUE
            JOIN public.alarmas_territorio at
                ON at.ciudad_normalizada = hg.nombre_google_normalizado
            JOIN todas_alarmas_delta tad ON tad.alarma_id = at.alarma_id
            WHERE pv.nivel = 'REGION'

            UNION ALL

            -- PAIS
            SELECT tad.alarma_id, tad.estado_alarma, tad.fecha_alarma,
                   tad.cnt_likes, tad.cnt_reenvios, tad.tipoalarma_id
            FROM pv
            JOIN public.paises pa ON pa.pais_id = pv.pais_id
            JOIN public.alarmas_territorio at
                ON lower(unaccent(trim(at.pais))) = lower(unaccent(pa.nombre_es))
            JOIN todas_alarmas_delta tad ON tad.alarma_id = at.alarma_id
            WHERE pv.nivel = 'PAIS'
        ),

        -- Cierres con fecha conocida dentro del delta
        -- (flag_es_cierre_alarma = TRUE en descripcionesalarmas o su espejo archivado)
        cierres_delta AS (
            (
                SELECT DISTINCT ON (da.alarma_id)
                    da.alarma_id,
                    da.fechadescripcion AS fecha_cierre
                FROM public.descripcionesalarmas da
                WHERE da.flag_es_cierre_alarma = TRUE
                  AND da.alarma_id IN (SELECT alarma_id FROM alarmas_del_politico)
                ORDER BY da.alarma_id, da.fechadescripcion ASC
            )
            UNION ALL
            (
                SELECT DISTINCT ON (mda.alarma_id)
                    mda.alarma_id,
                    mda.fechadescripcion AS fecha_cierre
                FROM migracion.migra_descripcionesalarmas mda
                WHERE mda.flag_es_cierre_alarma = TRUE
                  AND mda.alarma_id IN (SELECT alarma_id FROM alarmas_del_politico)
                ORDER BY mda.alarma_id, mda.fechadescripcion ASC
            )
        ),

        -- Cierres únicos (por si el alarma_id aparece en ambas fuentes)
        cierres_unicos AS (
            SELECT DISTINCT ON (alarma_id) alarma_id, fecha_cierre
            FROM cierres_delta
            ORDER BY alarma_id, fecha_cierre ASC
        ),

        -- Agregados del delta
        delta_agregado AS (
            SELECT
                COUNT(DISTINCT adp.alarma_id)                                    AS delta_total,
                COUNT(DISTINCT CASE WHEN adp.estado_alarma = 'C' THEN adp.alarma_id END) AS delta_cerradas,
                SUM(adp.cnt_likes)                                               AS delta_likes,
                SUM(adp.cnt_reenvios)                                            AS delta_reenvios,
                -- Suma de días para las alarmas cerradas con fecha conocida
                SUM(
                    CASE WHEN adp.estado_alarma = 'C' AND cu.fecha_cierre IS NOT NULL
                         THEN EXTRACT(EPOCH FROM (cu.fecha_cierre - adp.fecha_alarma)) / 86400.0
                    END
                )                                                                AS delta_sum_dias,
                COUNT(DISTINCT CASE WHEN adp.estado_alarma = 'C' AND cu.fecha_cierre IS NOT NULL
                                    THEN adp.alarma_id END)                      AS delta_cnt_cierres
            FROM alarmas_del_politico adp
            LEFT JOIN cierres_unicos cu ON cu.alarma_id = adp.alarma_id
        )

        SELECT
            delta_total,
            delta_cerradas,
            COALESCE(delta_likes, 0),
            COALESCE(delta_reenvios, 0),
            COALESCE(delta_sum_dias, 0),
            COALESCE(delta_cnt_cierres, 0)
        INTO
            v_delta_total,
            v_delta_cerradas,
            v_delta_likes,
            v_delta_reenvios,
            v_delta_sum_dias,
            v_delta_cnt_cierres
        FROM delta_agregado;

        -- ── 2b. Calcular aprobación ciudadana (no incremental, siempre desde cero) ──
        -- Las calificaciones 1-5 se escalan a 0-100%: promedio * 20.
        -- Se recalcula completo (no incremental) porque los votos pueden actualizarse.
        -- NOTA: se calcula ANTES del guard de delta vacío para que un nuevo voto
        --       siempre actualice mv_metricas_politico aunque no haya alarmas nuevas.
        SELECT
            COUNT(*)::INTEGER,
            ROUND(AVG(calificacion) * 20, 1)
        INTO
            v_cnt_votantes_aprobacion,
            v_pct_aprobacion
        FROM public.pol_aprobacion_ciudadana
        WHERE politico_id = rec_politico.politico_id;

        -- Si no hay registro anterior (primera vez) y tampoco hay alarmas ni votos, saltamos.
        -- Pero si YA existe un registro anterior, SIEMPRE procesamos para recalcular score_gestion,
        -- que cambia diariamente por el factor de días que llevan abiertas las alarmas vigentes.
        IF v_delta_total = 0 AND COALESCE(v_cnt_votantes_aprobacion, 0) = 0
           AND NOT v_anterior_encontrado THEN
            CONTINUE;
        END IF;

        -- Si no hay alarmas nuevas pero existe registro anterior, restaurar acumulados previos
        -- para que los bloques 4b (score_gestion) y 7 (mv_metricas_politico) puedan ejecutarse.
        IF v_delta_total = 0 AND v_anterior_encontrado THEN
            -- Restaurar acumulados del registro anterior para que el resto del flujo los use
            v_cnt_total              := COALESCE(rec_anterior.cnt_total,             0);
            v_cnt_cerradas           := COALESCE(rec_anterior.cnt_cerradas,          0);
            v_cnt_abiertas           := COALESCE(rec_anterior.cnt_abiertas,          0);
            v_cnt_likes              := COALESCE(rec_anterior.cnt_likes,             0);
            v_cnt_reenvios           := COALESCE(rec_anterior.cnt_reenvios,          0);
            v_pct_resolucion         := rec_anterior.pct_resolucion;
            v_avg_dias               := rec_anterior.avg_dias_resolucion;
            v_cnt_cierres_con_fecha  := COALESCE(rec_anterior.cnt_cierres_con_fecha, 0);
            v_tipos_alarma           := rec_anterior.tipos_alarma;
            v_fecha_desde            := rec_anterior.fecha_desde_alarmas;
            -- El flujo continúa hacia el bloque 4b (score_gestion) y luego actualiza mv_metricas_politico
        END IF;

        -- ── 3. Acumular sobre registro anterior (solo si hay delta nuevo) ───────
        IF v_delta_total > 0 THEN
            v_cnt_total   := COALESCE(rec_anterior.cnt_total,   0) + v_delta_total;
            v_cnt_cerradas:= COALESCE(rec_anterior.cnt_cerradas,0) + v_delta_cerradas;
            v_cnt_likes   := COALESCE(rec_anterior.cnt_likes,   0) + v_delta_likes;
            v_cnt_reenvios:= COALESCE(rec_anterior.cnt_reenvios,0) + v_delta_reenvios;

            v_cnt_abiertas   := v_cnt_total - v_cnt_cerradas;
            v_pct_resolucion := ROUND(v_cnt_cerradas * 100.0 / NULLIF(v_cnt_total, 0), 1);

            -- avg_dias_resolucion: promedio ponderado
            v_cnt_cierres_con_fecha := COALESCE(rec_anterior.cnt_cierres_con_fecha, 0) + v_delta_cnt_cierres;
            IF v_cnt_cierres_con_fecha = 0 THEN
                v_avg_dias := NULL;
            ELSE
                v_avg_dias := ROUND(
                    (
                        COALESCE(rec_anterior.avg_dias_resolucion, 0) * COALESCE(rec_anterior.cnt_cierres_con_fecha, 0)
                        + v_delta_sum_dias
                    ) / v_cnt_cierres_con_fecha
                , 1);
            END IF;

            -- fecha_desde: conservar la más antigua (o usar fecha_corte si es primera vez)
            IF NOT v_anterior_encontrado THEN
                SELECT MIN(a.fecha_alarma)
                  INTO v_fecha_desde
                  FROM (
                    SELECT fecha_alarma FROM public.alarmas
                    UNION ALL
                    SELECT fecha_alarma FROM migracion.migra_alarmas
                  ) a;
                IF v_fecha_desde IS NULL THEN v_fecha_desde := v_ahora; END IF;
            ELSE
                v_fecha_desde := rec_anterior.fecha_desde_alarmas;
            END IF;
        END IF;
        -- Cuando v_delta_total = 0, los acumulados ya fueron restaurados desde rec_anterior arriba

        -- ── 4. Calcular distribución por tipo de alarma (JSONB) ──────────────
        -- Solo recalcular si hay alarmas nuevas; si no, v_tipos_alarma ya tiene el valor de rec_anterior
        IF v_delta_total > 0 THEN
        WITH
        tipos_anteriores AS (
            SELECT
                (elem->>'tipoalarma_id')::INTEGER AS tipoalarma_id,
                (elem->>'cnt')::INTEGER           AS cnt
            FROM jsonb_array_elements(COALESCE(rec_anterior.tipos_alarma, '[]'::jsonb)) AS elem
        ),
        tipos_delta AS (
            SELECT tipoalarma_id, COUNT(DISTINCT alarma_id)::INTEGER AS cnt
            FROM (
                SELECT tipoalarma_id, alarma_id FROM public.alarmas
                WHERE fecha_alarma > v_fecha_corte
                  AND alarma_id IN (
                      SELECT alarma_id FROM public.alarmas_territorio at
                      -- Solo alarmas que ya computamos en el delta del político
                  )
                UNION ALL
                SELECT tipoalarma_id, alarma_id FROM migracion.migra_alarmas
                WHERE fecha_alarma > v_fecha_corte
            ) src
            GROUP BY tipoalarma_id
        ),
        tipos_merged AS (
            SELECT
                COALESCE(ta.tipoalarma_id, td.tipoalarma_id) AS tipoalarma_id,
                COALESCE(ta.cnt, 0) + COALESCE(td.cnt, 0)   AS cnt
            FROM tipos_anteriores ta
            FULL OUTER JOIN tipos_delta td ON td.tipoalarma_id = ta.tipoalarma_id
        )
        SELECT jsonb_agg(
                   jsonb_build_object(
                       'tipoalarma_id', tipoalarma_id,
                       'cnt', cnt,
                       'pct', ROUND(cnt * 100.0 / NULLIF(v_cnt_total, 0), 1)
                   ) ORDER BY cnt DESC
               )
          INTO v_tipos_alarma
          FROM tipos_merged
         WHERE cnt > 0;
        END IF;

        -- ── 4b. Calcular score_gestion ────────────────────────────────────────
        -- FORMULA: score_gestion = pct_resolucion - penalizacion_abiertas
        --
        -- score_base = pct_resolucion (0–100): refleja el historial de cumplimiento.
        --   El trabajo pasado (alarmas cerradas) ya está capturado aquí.
        --   No se agrega premio adicional por cerrar, para evitar que el volumen
        --   histórico opaque la situación actual.
        --
        -- penalizacion = LEAST(40, pen_bruta × 0.333)
        --   pen_bruta = SUM(dias_abierta × factor_viralidad) por cada alarma abierta HOY.
        --   factor_viralidad = (1 + LN(1+likes)) × (1 + LN(1+reenvios))
        --   coef 0.333: 1 alarma abierta 30 días sin viralidad → -10 puntos.
        --              1 alarma abierta 17 días con 1 like    → -9.8 puntos.
        --   cap 40: techo de penalización para casos extremos.
        --
        -- Solo alarmas en public.alarmas (activas); archivadas en migración
        -- no tienen estado_alarma confiable para determinar si siguen abiertas.

        v_score_base := ROUND(v_cnt_cerradas * 100.0 / NULLIF(v_cnt_total, 0), 1);

        -- Penalización: alarmas abiertas HOY del político × días × viralidad
        WITH pv_score AS (
            SELECT v.politico_id, v.territorio_id, NULL::CHAR(2) AS pais_id, pt.nivel
            FROM public.pol_vigencias v
            JOIN public.pol_territorios pt ON pt.territorio_id = v.territorio_id
            WHERE v.activo = TRUE
              AND v.territorio_id IS NOT NULL
              AND CURRENT_DATE BETWEEN v.fecha_inicio AND COALESCE(v.fecha_fin, 'infinity'::date)
              AND v.politico_id = rec_politico.politico_id
            UNION ALL
            SELECT v.politico_id, NULL::INTEGER, v.pais_id, 'PAIS'
            FROM public.pol_vigencias v
            WHERE v.activo = TRUE
              AND v.pais_id IS NOT NULL
              AND CURRENT_DATE BETWEEN v.fecha_inicio AND COALESCE(v.fecha_fin, 'infinity'::date)
              AND v.politico_id = rec_politico.politico_id
        ),
        alarmas_abiertas_politico AS (
            SELECT DISTINCT a.alarma_id, a.cnt_likes, a.cnt_reenvios, a.fecha_alarma
            FROM public.alarmas a
            JOIN public.alarmas_territorio at ON at.alarma_id = a.alarma_id
            WHERE a.estado_alarma IS NULL
              AND COALESCE(a.calificacion_alarma, 100) >= 50
              AND (
                  EXISTS (
                      SELECT 1 FROM pv_score pv
                      JOIN public.pol_homologacion_google hg
                          ON hg.territorio_id = pv.territorio_id AND hg.activo = TRUE
                      WHERE (pv.nivel = 'DISTRITO' AND hg.nivel_google = 'barrio'  AND at.barrio_normalizado  = hg.nombre_google_normalizado)
                         OR (pv.nivel = 'CIUDAD'   AND hg.nivel_google = 'ciudad'  AND at.ciudad_normalizada  = hg.nombre_google_normalizado)
                  )
                  OR EXISTS (
                      SELECT 1 FROM pv_score pv
                      JOIN public.pol_territorios pt_ciudad ON pt_ciudad.parent_id = pv.territorio_id AND pt_ciudad.nivel = 'CIUDAD'
                      JOIN public.pol_homologacion_google hg ON hg.territorio_id = pt_ciudad.territorio_id AND hg.nivel_google = 'ciudad' AND hg.activo = TRUE
                      WHERE pv.nivel = 'REGION' AND at.ciudad_normalizada = hg.nombre_google_normalizado
                  )
                  OR EXISTS (
                      SELECT 1 FROM pv_score pv
                      JOIN public.paises pa ON pa.pais_id = pv.pais_id
                      WHERE pv.nivel = 'PAIS'
                        AND lower(unaccent(trim(at.pais))) = lower(unaccent(pa.nombre_es))
                  )
              )
        )
        SELECT COALESCE(SUM(
            EXTRACT(EPOCH FROM (NOW() - a.fecha_alarma)) / 86400.0
            * (1.0 + LN(1.0 + COALESCE(a.cnt_likes,    0)))
            * (1.0 + LN(1.0 + COALESCE(a.cnt_reenvios, 0)))
        ), 0)
        INTO v_penalizacion_bruta
        FROM alarmas_abiertas_politico a;

        -- coef 0.333: calibrado para que 1 alarma abierta 30 días sin likes = -10 puntos
        -- cap 40: penalización máxima en casos extremos (muchas alarmas abiertas y virales)
        v_penalizacion := LEAST(40.0, v_penalizacion_bruta * 0.333);

        -- Score final (0–100): base histórica descontada por situación abierta actual
        v_score_gestion := GREATEST(0, LEAST(100,
            COALESCE(v_score_base, 0) - v_penalizacion
        ));

        -- ── 5 & 6. SCD Tipo 2: solo si hubo delta real de alarmas o es la primera vez ──
        -- Si solo se recalcula score_gestion sin alarmas nuevas, no creamos fila histórica nueva
        -- (evita inflar metricas_politico con entradas idénticas en contadores).
        -- El score actualizado se refleja igualmente en mv_metricas_politico (caché API).
        IF v_delta_total > 0 OR NOT v_anterior_encontrado THEN

            -- ── 5. Cerrar registro anterior (SCD Tipo 2) ─────────────────────
            UPDATE public.metricas_politico
               SET fecha_fin_vigencia = v_ahora
             WHERE politico_id = rec_politico.politico_id
               AND fecha_fin_vigencia IS NULL;

            -- ── 6. Insertar nuevo registro vigente en metricas_politico ──────
            INSERT INTO public.metricas_politico (
                politico_id,
                fecha_desde_alarmas,
                fecha_hasta_alarmas,
                cnt_total,
                cnt_abiertas,
                cnt_cerradas,
                pct_resolucion,
                cnt_likes,
                cnt_reenvios,
                avg_dias_resolucion,
                cnt_cierres_con_fecha,
                tipos_alarma,
                score_gestion,
                fecha_inicio_vigencia,
                fecha_fin_vigencia,
                fecha_calculo
            ) VALUES (
                rec_politico.politico_id,
                v_fecha_desde,
                v_ahora,
                v_cnt_total,
                v_cnt_abiertas,
                v_cnt_cerradas,
                v_pct_resolucion,
                v_cnt_likes,
                v_cnt_reenvios,
                v_avg_dias,
                v_cnt_cierres_con_fecha,
                v_tipos_alarma,
                v_score_gestion,
                v_ahora,
                NULL,    -- vigente
                v_ahora
            );

        ELSE
            -- Solo actualizamos score_gestion en el registro SCD2 vigente actual
            UPDATE public.metricas_politico
               SET score_gestion  = v_score_gestion,
                   fecha_calculo  = v_ahora
             WHERE politico_id    = rec_politico.politico_id
               AND fecha_fin_vigencia IS NULL;
        END IF;

        -- ── 7. Sincronizar mv_metricas_politico (caché de lectura para la API) ──
        INSERT INTO public.mv_metricas_politico (
            politico_id,
            cnt_total,
            cnt_abiertas,
            cnt_cerradas,
            pct_resolucion,
            cnt_likes,
            cnt_reenvios,
            avg_dias_resolucion,
            fecha_calculo,
            pct_aprobacion,
            cnt_votantes_aprobacion,
            score_gestion
        ) VALUES (
            rec_politico.politico_id,
            v_cnt_total,
            v_cnt_abiertas,
            v_cnt_cerradas,
            v_pct_resolucion,
            v_cnt_likes,
            v_cnt_reenvios,
            v_avg_dias,
            v_ahora,
            v_pct_aprobacion,
            COALESCE(v_cnt_votantes_aprobacion, 0),
            v_score_gestion
        )
        ON CONFLICT (politico_id) DO UPDATE SET
            cnt_total                = EXCLUDED.cnt_total,
            cnt_abiertas             = EXCLUDED.cnt_abiertas,
            cnt_cerradas             = EXCLUDED.cnt_cerradas,
            pct_resolucion           = EXCLUDED.pct_resolucion,
            cnt_likes                = EXCLUDED.cnt_likes,
            cnt_reenvios             = EXCLUDED.cnt_reenvios,
            avg_dias_resolucion      = EXCLUDED.avg_dias_resolucion,
            fecha_calculo            = EXCLUDED.fecha_calculo,
            pct_aprobacion           = EXCLUDED.pct_aprobacion,
            cnt_votantes_aprobacion  = EXCLUDED.cnt_votantes_aprobacion,
            score_gestion            = EXCLUDED.score_gestion;

        -- ── 8. Sincronizar mv_metricas_politico_tipos ─────────────────────────
        DELETE FROM public.mv_metricas_politico_tipos
         WHERE politico_id = rec_politico.politico_id;

        INSERT INTO public.mv_metricas_politico_tipos (politico_id, tipoalarma_id, cnt, pct)
        SELECT
            rec_politico.politico_id,
            (elem->>'tipoalarma_id')::BIGINT,
            (elem->>'cnt')::INTEGER,
            (elem->>'pct')::NUMERIC(5,1)
        FROM jsonb_array_elements(COALESCE(v_tipos_alarma, '[]'::jsonb)) AS elem
        ON CONFLICT (politico_id, tipoalarma_id) DO UPDATE SET
            cnt = EXCLUDED.cnt,
            pct = EXCLUDED.pct;

    END LOOP;

END;
$$;

COMMENT ON PROCEDURE public.refrescar_metricas_politico() IS
'Cálculo incremental acumulativo de métricas de desempeño por político. Por cada político vigente: (1) determina el corte desde fecha_hasta_alarmas del registro vigente en metricas_politico; (2) calcula el delta consultando public.alarmas UNION migracion.migra_alarmas filtradas por alarmas_territorio; (3) acumula sobre totales previos con promedio ponderado para avg_dias_resolucion; (4) cierra el registro anterior (SCD Tipo 2) e inserta el nuevo; (5) sincroniza mv_metricas_politico (caché API) y mv_metricas_politico_tipos. Se ejecuta diariamente a las 0:00 UTC vía pg_cron. Rediseñado 2026-03-10 para soportar archivado ETL.';
