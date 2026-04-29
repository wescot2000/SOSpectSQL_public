-- PROCEDURE: public.calcular_metricas_politicos()
-- Módulo político: recalcula los contadores en pol_metricas_territorio.
--
-- Se ejecuta periódicamente (cron diario o manualmente).
-- Solo lee alarmas que están en PostgreSQL (no migradas a S3, < 120 días).
-- Usa UPSERT (INSERT ON CONFLICT DO UPDATE) para ser idempotente.
--
-- Períodos calculados: '24H', '7D', '30D'
-- (Se usa 24H en vez de HOY para evitar inconsistencias de timezone)
--
-- Prerequisitos:
--   CREATE EXTENSION IF NOT EXISTS unaccent;
--   Tables: pol_territorios, pol_homologacion_google, pol_metricas_territorio
--   Tables: alarmas_territorio (con columnas barrio_normalizado, ciudad_normalizada)
--   Tables: alarmas, tipoalarma, paises

CREATE OR REPLACE PROCEDURE public.calcular_metricas_politicos()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_periodos  TEXT[]  := ARRAY['24H', '7D', '30D'];
    v_periodo   TEXT;
    v_intervalo INTERVAL;
    v_fecha_desde TIMESTAMP WITH TIME ZONE;
BEGIN
    FOREACH v_periodo IN ARRAY v_periodos LOOP

        -- Determinar ventana temporal
        v_intervalo := CASE v_periodo
            WHEN '24H' THEN INTERVAL '24 hours'
            WHEN '7D'  THEN INTERVAL '7 days'
            WHEN '30D' THEN INTERVAL '30 days'
        END;
        v_fecha_desde := now() - v_intervalo;

        -- ══════════════════════════════════════════════════════════════════
        -- 1. DISTRITOS (comunas/localidades/JAL)
        --    Join alarmas_territorio.barrio_normalizado → pol_homologacion_google
        -- ══════════════════════════════════════════════════════════════════
        INSERT INTO public.pol_metricas_territorio
            (territorio_id, pais_id, periodo, cnt_alarmas, cnt_alarmas_politico, fecha_calculo)
        SELECT
            hg.territorio_id,
            NULL,
            v_periodo,
            COUNT(a.alarma_id),
            COUNT(a.alarma_id) FILTER (WHERE ta.es_indicador_politico = TRUE),
            now()
        FROM public.alarmas_territorio at_raw
        JOIN public.paises p
            ON lower(unaccent(trim(at_raw.pais))) = lower(unaccent(p.nombre_es))
        JOIN public.pol_homologacion_google hg
            ON COALESCE(at_raw.barrio_normalizado, lower(unaccent(trim(at_raw.barrio))))
               = hg.nombre_google_normalizado
            AND hg.nivel_google = 'barrio'
            AND hg.pais_id = p.pais_id
            AND hg.activo = TRUE
        JOIN public.pol_territorios pt
            ON pt.territorio_id = hg.territorio_id
            AND pt.nivel = 'DISTRITO'
        JOIN public.alarmas a
            ON a.alarma_id = at_raw.alarma_id
        JOIN public.tipoalarma ta
            ON ta.tipoalarma_id = a.tipoalarma_id
        WHERE a.fecha_alarma >= v_fecha_desde
        GROUP BY hg.territorio_id
        ON CONFLICT (territorio_id, pais_id, periodo)
            WHERE territorio_id IS NOT NULL AND pais_id IS NULL
        DO UPDATE SET
            cnt_alarmas          = EXCLUDED.cnt_alarmas,
            cnt_alarmas_politico = EXCLUDED.cnt_alarmas_politico,
            fecha_calculo        = EXCLUDED.fecha_calculo;

        -- ══════════════════════════════════════════════════════════════════
        -- 2. CIUDADES (municipios)
        --    Join alarmas_territorio.ciudad_normalizada → pol_homologacion_google
        -- ══════════════════════════════════════════════════════════════════
        INSERT INTO public.pol_metricas_territorio
            (territorio_id, pais_id, periodo, cnt_alarmas, cnt_alarmas_politico, fecha_calculo)
        SELECT
            hg.territorio_id,
            NULL,
            v_periodo,
            COUNT(a.alarma_id),
            COUNT(a.alarma_id) FILTER (WHERE ta.es_indicador_politico = TRUE),
            now()
        FROM public.alarmas_territorio at_raw
        JOIN public.paises p
            ON lower(unaccent(trim(at_raw.pais))) = lower(unaccent(p.nombre_es))
        JOIN public.pol_homologacion_google hg
            ON COALESCE(at_raw.ciudad_normalizada, lower(unaccent(trim(at_raw.ciudad))))
               = hg.nombre_google_normalizado
            AND hg.nivel_google = 'ciudad'
            AND hg.pais_id = p.pais_id
            AND hg.activo = TRUE
        JOIN public.pol_territorios pt
            ON pt.territorio_id = hg.territorio_id
            AND pt.nivel = 'CIUDAD'
        JOIN public.alarmas a
            ON a.alarma_id = at_raw.alarma_id
        JOIN public.tipoalarma ta
            ON ta.tipoalarma_id = a.tipoalarma_id
        WHERE a.fecha_alarma >= v_fecha_desde
        GROUP BY hg.territorio_id
        ON CONFLICT (territorio_id, pais_id, periodo)
            WHERE territorio_id IS NOT NULL AND pais_id IS NULL
        DO UPDATE SET
            cnt_alarmas          = EXCLUDED.cnt_alarmas,
            cnt_alarmas_politico = EXCLUDED.cnt_alarmas_politico,
            fecha_calculo        = EXCLUDED.fecha_calculo;

        -- ══════════════════════════════════════════════════════════════════
        -- 3. REGIONES (departamentos/estados)
        --    Se agrega sumando las métricas de sus CIUDADES hijas
        -- ══════════════════════════════════════════════════════════════════
        INSERT INTO public.pol_metricas_territorio
            (territorio_id, pais_id, periodo, cnt_alarmas, cnt_alarmas_politico, fecha_calculo)
        SELECT
            region.territorio_id,
            NULL,
            v_periodo,
            COALESCE(SUM(mt_ciudad.cnt_alarmas), 0),
            COALESCE(SUM(mt_ciudad.cnt_alarmas_politico), 0),
            now()
        FROM public.pol_territorios region
        JOIN public.pol_territorios ciudad
            ON ciudad.parent_id = region.territorio_id
            AND ciudad.nivel = 'CIUDAD'
        LEFT JOIN public.pol_metricas_territorio mt_ciudad
            ON mt_ciudad.territorio_id = ciudad.territorio_id
            AND mt_ciudad.periodo = v_periodo
            AND mt_ciudad.pais_id IS NULL
        WHERE region.nivel = 'REGION'
        GROUP BY region.territorio_id
        ON CONFLICT (territorio_id, pais_id, periodo)
            WHERE territorio_id IS NOT NULL AND pais_id IS NULL
        DO UPDATE SET
            cnt_alarmas          = EXCLUDED.cnt_alarmas,
            cnt_alarmas_politico = EXCLUDED.cnt_alarmas_politico,
            fecha_calculo        = EXCLUDED.fecha_calculo;

        -- ══════════════════════════════════════════════════════════════════
        -- 4. PAIS (para el Presidente)
        --    Join alarmas_territorio.pais → paises.nombre_es → paises.pais_id
        -- ══════════════════════════════════════════════════════════════════
        INSERT INTO public.pol_metricas_territorio
            (territorio_id, pais_id, periodo, cnt_alarmas, cnt_alarmas_politico, fecha_calculo)
        SELECT
            NULL,
            p.pais_id,
            v_periodo,
            COUNT(a.alarma_id),
            COUNT(a.alarma_id) FILTER (WHERE ta.es_indicador_politico = TRUE),
            now()
        FROM public.alarmas_territorio at_raw
        JOIN public.paises p
            ON lower(unaccent(trim(at_raw.pais))) = lower(unaccent(p.nombre_es))
        JOIN public.alarmas a
            ON a.alarma_id = at_raw.alarma_id
        JOIN public.tipoalarma ta
            ON ta.tipoalarma_id = a.tipoalarma_id
        WHERE a.fecha_alarma >= v_fecha_desde
        GROUP BY p.pais_id
        ON CONFLICT (territorio_id, pais_id, periodo)
            WHERE territorio_id IS NULL AND pais_id IS NOT NULL
        DO UPDATE SET
            cnt_alarmas          = EXCLUDED.cnt_alarmas,
            cnt_alarmas_politico = EXCLUDED.cnt_alarmas_politico,
            fecha_calculo        = EXCLUDED.fecha_calculo;

    END LOOP;

    RAISE NOTICE 'calcular_metricas_politicos completado a las %', now();
END
$BODY$;

COMMENT ON PROCEDURE public.calcular_metricas_politicos() IS
'Recalcula contadores de alarmas en pol_metricas_territorio para los períodos 24H, 7D y 30D. Calcula en orden: DISTRITO → CIUDAD → REGION (suma de ciudades) → PAIS. Ejecutar periódicamente (cron diario recomendado).';
