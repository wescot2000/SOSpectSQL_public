-- Procedure: public.refrescar_metricas_zona
-- Precálculo incremental de métricas de reportes básicos por celda geoespacial de 0.01°×0.01°.
--
-- ARQUITECTURA:
--   1. Fuente de verdad: public.metricas_zona (SCD Tipo 2)
--   2. Caché de lectura: public.mv_metricas_zona (una fila por celda, para la API)
--
-- LÓGICA INCREMENTAL:
--   Por cada celda con actividad se determina la última fecha procesada
--   (fecha_hasta_alarmas del registro vigente en metricas_zona). Solo se procesan
--   alarmas con fecha_alarma > ese corte. Los resultados se acumulan sobre totales previos.
--
-- FALSAS ALARMAS:
--   Se excluyen del cómputo de cnt_total y cnt_ciertas las alarmas con calificacion_alarma < 50.
--   Se contabilizan por separado en cnt_falsas para referencia.
--
-- CELDAS ACTIVAS:
--   Solo se procesan celdas donde hubo alarmas en los últimos 30 días. Esto garantiza
--   que el procedure escala por actividad real, no por extensión geográfica.
--
-- LLAMADA MANUAL:
--   CALL public.refrescar_metricas_zona();
--
-- CRON DIARIO A LAS 0:05 UTC (5 minutos tras refrescar_metricas_politico):
--   SELECT cron.schedule('Metricas zona', '5 0 * * *', 'CALL public.refrescar_metricas_zona()');
--
-- Creado: 2026-04-07
--

CREATE OR REPLACE PROCEDURE public.refrescar_metricas_zona()
LANGUAGE plpgsql
AS $$
DECLARE
    rec_celda             RECORD;    -- celda activa en iteración
    rec_anterior          RECORD;    -- registro vigente en metricas_zona (puede ser NULL)
    v_anterior_encontrado BOOLEAN;
    v_fecha_corte         TIMESTAMPTZ;
    v_ahora               TIMESTAMPTZ := NOW();

    -- Delta acumulado de la celda
    v_cnt_total               INTEGER;
    v_cnt_ciertas             INTEGER;
    v_cnt_falsas              INTEGER;
    v_pct_ciertas             NUMERIC(5,1);
    v_tipos_alarma            JSONB;
    v_avg_minutos_cal         NUMERIC(8,1);
    v_cnt_capturas            INTEGER;
    v_cnt_personas_en_zona    INTEGER;
    v_fecha_desde             TIMESTAMPTZ;

    -- Delta nuevo (solo alarmas desde fecha_corte)
    v_delta_total             INTEGER;
    v_delta_ciertas           INTEGER;
    v_delta_falsas            INTEGER;
    v_delta_capturas          INTEGER;
    v_delta_sum_minutos       NUMERIC;
    v_delta_cnt_calificadas   INTEGER;

BEGIN

    -- ══════════════════════════════════════════════════════════════════════════
    -- Iterar sobre celdas con actividad en los últimos 30 días
    -- ══════════════════════════════════════════════════════════════════════════
    FOR rec_celda IN
        SELECT
            ROUND(a.latitud  / 0.01) * 0.01::NUMERIC(7,4) AS celda_lat,
            ROUND(a.longitud / 0.01) * 0.01::NUMERIC(7,4) AS celda_lon
        FROM public.alarmas a
        WHERE a.fecha_alarma >= NOW() - INTERVAL '30 days'
          AND a.latitud  IS NOT NULL
          AND a.longitud IS NOT NULL
        GROUP BY 1, 2
    LOOP

        -- ── 1. Leer registro vigente en metricas_zona ─────────────────────────
        SELECT *
          INTO rec_anterior
          FROM public.metricas_zona
         WHERE celda_lat = rec_celda.celda_lat
           AND celda_lon = rec_celda.celda_lon
           AND fecha_fin_vigencia IS NULL;
        v_anterior_encontrado := FOUND;

        IF NOT v_anterior_encontrado THEN
            v_fecha_corte := TIMESTAMPTZ '1900-01-01 00:00:00+00';
        ELSE
            v_fecha_corte := rec_anterior.fecha_hasta_alarmas;
        END IF;

        -- ── 2. Calcular delta de alarmas nuevas desde fecha_corte ─────────────
        WITH alarmas_celda AS (
            SELECT
                a.alarma_id,
                a.estado_alarma,
                a.fecha_alarma,
                a.tipoalarma_id,
                a.calificacion_alarma,
                COALESCE(a.cnt_likes, 0)    AS cnt_likes,
                COALESCE(a.cnt_reenvios, 0) AS cnt_reenvios
            FROM public.alarmas a
            WHERE a.fecha_alarma > v_fecha_corte
              AND a.latitud  IS NOT NULL
              AND a.longitud IS NOT NULL
              AND ROUND(a.latitud  / 0.01) * 0.01 = rec_celda.celda_lat
              AND ROUND(a.longitud / 0.01) * 0.01 = rec_celda.celda_lon
        ),
        -- Primera calificación de cada alarma (para avg_minutos_calificacion)
        primera_calificacion AS (
            SELECT DISTINCT ON (da.alarma_id)
                da.alarma_id,
                EXTRACT(EPOCH FROM (da.fechadescripcion - ac.fecha_alarma)) / 60.0 AS minutos_hasta_cal
            FROM public.descripcionesalarmas da
            JOIN alarmas_celda ac ON ac.alarma_id = da.alarma_id
            WHERE da.calificaciondescripcion IS NOT NULL
            ORDER BY da.alarma_id, da.fechadescripcion ASC
        ),
        -- Capturas confirmadas
        capturas AS (
            SELECT DISTINCT da.alarma_id
            FROM public.descripcionesalarmas da
            JOIN alarmas_celda ac ON ac.alarma_id = da.alarma_id
            WHERE da.flag_hubo_captura = TRUE
        ),
        delta AS (
            SELECT
                -- Alarmas reales (excluye falsas: calificacion_alarma < 50)
                COUNT(DISTINCT CASE WHEN COALESCE(ac.calificacion_alarma, 100) >= 50
                                    THEN ac.alarma_id END)::INTEGER                         AS delta_total,
                COUNT(DISTINCT CASE WHEN COALESCE(ac.calificacion_alarma, 100) >= 50
                                         AND ac.estado_alarma = 'C'
                                    THEN ac.alarma_id END)::INTEGER                         AS delta_ciertas,
                COUNT(DISTINCT CASE WHEN COALESCE(ac.calificacion_alarma, 100) < 50
                                    THEN ac.alarma_id END)::INTEGER                         AS delta_falsas,
                COUNT(DISTINCT c.alarma_id)::INTEGER                                        AS delta_capturas,
                SUM(pc.minutos_hasta_cal)                                                   AS delta_sum_minutos,
                COUNT(DISTINCT pc.alarma_id)::INTEGER                                       AS delta_cnt_calificadas
            FROM alarmas_celda ac
            LEFT JOIN primera_calificacion pc ON pc.alarma_id = ac.alarma_id
            LEFT JOIN capturas c ON c.alarma_id = ac.alarma_id
        )
        SELECT delta_total, delta_ciertas, delta_falsas, delta_capturas,
               COALESCE(delta_sum_minutos, 0), COALESCE(delta_cnt_calificadas, 0)
          INTO v_delta_total, v_delta_ciertas, v_delta_falsas, v_delta_capturas,
               v_delta_sum_minutos, v_delta_cnt_calificadas
          FROM delta;

        -- Si no hay nada nuevo, saltar esta celda
        IF v_delta_total = 0 AND v_delta_falsas = 0 THEN
            CONTINUE;
        END IF;

        -- ── 3. Acumular sobre registro anterior ──────────────────────────────
        v_cnt_total   := COALESCE(rec_anterior.cnt_total,   0) + v_delta_total;
        v_cnt_ciertas := COALESCE(rec_anterior.cnt_ciertas, 0) + v_delta_ciertas;
        v_cnt_falsas  := COALESCE(rec_anterior.cnt_falsas,  0) + v_delta_falsas;
        v_cnt_capturas:= COALESCE(rec_anterior.cnt_capturas,0) + v_delta_capturas;

        v_pct_ciertas := ROUND(v_cnt_ciertas * 100.0 / NULLIF(v_cnt_total, 0), 1);

        -- Promedio ponderado de minutos hasta calificación
        DECLARE
            v_prev_peso  INTEGER := COALESCE(
                (SELECT cnt_total FROM public.metricas_zona
                  WHERE celda_lat = rec_celda.celda_lat
                    AND celda_lon = rec_celda.celda_lon
                    AND fecha_fin_vigencia IS NULL), 0);
            v_prev_avg   NUMERIC := COALESCE(rec_anterior.avg_minutos_calificacion, 0);
        BEGIN
            IF (v_delta_cnt_calificadas + v_prev_peso) = 0 THEN
                v_avg_minutos_cal := NULL;
            ELSE
                v_avg_minutos_cal := ROUND(
                    (v_prev_avg * v_prev_peso + v_delta_sum_minutos)
                    / NULLIF(v_delta_cnt_calificadas + v_prev_peso, 0)
                , 1);
            END IF;
        END;

        -- fecha_desde
        IF NOT v_anterior_encontrado THEN
            SELECT MIN(a.fecha_alarma)
              INTO v_fecha_desde
              FROM public.alarmas a
             WHERE ROUND(a.latitud  / 0.01) * 0.01 = rec_celda.celda_lat
               AND ROUND(a.longitud / 0.01) * 0.01 = rec_celda.celda_lon;
            IF v_fecha_desde IS NULL THEN v_fecha_desde := v_ahora; END IF;
        ELSE
            v_fecha_desde := rec_anterior.fecha_desde_alarmas;
        END IF;

        -- ── 4. Personas en zona (siempre recalculado, no incremental) ─────────
        SELECT COUNT(DISTINCT u.persona_id)::INTEGER
          INTO v_cnt_personas_en_zona
          FROM public.ubicaciones u
         WHERE u."Tipo" = 'P'
           AND ROUND(u.latitud  / 0.01) * 0.01 = rec_celda.celda_lat
           AND ROUND(u.longitud / 0.01) * 0.01 = rec_celda.celda_lon
           AND u.ubicacion_id IN (
               SELECT MAX(u2.ubicacion_id)
                 FROM public.ubicaciones u2
                WHERE u2."Tipo" = 'P'
                GROUP BY u2.persona_id
           );

        -- ── 5. Distribución por tipo de alarma (JSONB) ────────────────────────
        WITH tipos_anteriores AS (
            SELECT
                (elem->>'tipoalarma_id')::INTEGER AS tipoalarma_id,
                (elem->>'cnt')::INTEGER           AS cnt
            FROM jsonb_array_elements(COALESCE(rec_anterior.tipos_alarma, '[]'::jsonb)) AS elem
        ),
        tipos_delta AS (
            SELECT a.tipoalarma_id, COUNT(DISTINCT a.alarma_id)::INTEGER AS cnt
            FROM public.alarmas a
            WHERE a.fecha_alarma > v_fecha_corte
              AND a.latitud  IS NOT NULL
              AND a.longitud IS NOT NULL
              AND ROUND(a.latitud  / 0.01) * 0.01 = rec_celda.celda_lat
              AND ROUND(a.longitud / 0.01) * 0.01 = rec_celda.celda_lon
              AND COALESCE(a.calificacion_alarma, 100) >= 50   -- excluir falsas
            GROUP BY a.tipoalarma_id
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

        -- ── 6. Cerrar registro anterior (SCD Tipo 2) ──────────────────────────
        UPDATE public.metricas_zona
           SET fecha_fin_vigencia = v_ahora
         WHERE celda_lat = rec_celda.celda_lat
           AND celda_lon = rec_celda.celda_lon
           AND fecha_fin_vigencia IS NULL;

        -- ── 7. Insertar nuevo registro vigente en metricas_zona ───────────────
        INSERT INTO public.metricas_zona (
            celda_lat, celda_lon,
            fecha_desde_alarmas, fecha_hasta_alarmas,
            tipos_alarma,
            cnt_total, cnt_ciertas, cnt_falsas, pct_ciertas,
            avg_minutos_calificacion, cnt_capturas, cnt_personas_en_zona,
            fecha_inicio_vigencia, fecha_fin_vigencia, fecha_calculo
        ) VALUES (
            rec_celda.celda_lat, rec_celda.celda_lon,
            v_fecha_desde, v_ahora,
            v_tipos_alarma,
            v_cnt_total, v_cnt_ciertas, v_cnt_falsas, v_pct_ciertas,
            v_avg_minutos_cal, v_cnt_capturas, v_cnt_personas_en_zona,
            v_ahora, NULL, v_ahora
        );

        -- ── 8. Sincronizar mv_metricas_zona (caché de lectura para la API) ────
        INSERT INTO public.mv_metricas_zona (
            celda_lat, celda_lon,
            tipos_alarma,
            cnt_total, cnt_ciertas, cnt_falsas, pct_ciertas,
            avg_minutos_calificacion, cnt_capturas, cnt_personas_en_zona,
            fecha_calculo
        ) VALUES (
            rec_celda.celda_lat, rec_celda.celda_lon,
            v_tipos_alarma,
            v_cnt_total, v_cnt_ciertas, v_cnt_falsas, v_pct_ciertas,
            v_avg_minutos_cal, v_cnt_capturas, v_cnt_personas_en_zona,
            v_ahora
        )
        ON CONFLICT (celda_lat, celda_lon) DO UPDATE SET
            tipos_alarma             = EXCLUDED.tipos_alarma,
            cnt_total                = EXCLUDED.cnt_total,
            cnt_ciertas              = EXCLUDED.cnt_ciertas,
            cnt_falsas               = EXCLUDED.cnt_falsas,
            pct_ciertas              = EXCLUDED.pct_ciertas,
            avg_minutos_calificacion = EXCLUDED.avg_minutos_calificacion,
            cnt_capturas             = EXCLUDED.cnt_capturas,
            cnt_personas_en_zona     = EXCLUDED.cnt_personas_en_zona,
            fecha_calculo            = EXCLUDED.fecha_calculo;

    END LOOP;

END;
$$;

COMMENT ON PROCEDURE public.refrescar_metricas_zona() IS
'Precálculo incremental de métricas de reportes básicos por celda geoespacial 0.01°×0.01° (~1.1 km). Procesa solo celdas con actividad en los últimos 30 días. Por cada celda: (1) determina el corte desde fecha_hasta_alarmas del registro vigente; (2) calcula el delta de alarmas nuevas excluyendo falsas (calificacion_alarma < 50); (3) acumula sobre totales previos; (4) cierra el registro anterior (SCD Tipo 2) e inserta el nuevo; (5) sincroniza mv_metricas_zona (caché API). Reemplaza las funciones ConsultaParticipacionTiposAlarma, MetricasAlarmasEnZona y MetricasSueltasBasicas. Se ejecuta a las 0:05 UTC tras refrescar_metricas_politico. Creado: 2026-04-07.';
