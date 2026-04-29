-- View: public.vw_tipoalarma_estadistica_30d
-- Vista de estadísticas de tipos de alarma en los últimos 30 días
-- Fecha: 2025-12-20
-- Referencia: ManualGeneralSOSpect.md [CAMBIO - 19-12-2025 14:00]

-- DROP VIEW IF EXISTS public.vw_tipoalarma_estadistica_30d;

CREATE OR REPLACE VIEW public.vw_tipoalarma_estadistica_30d AS
WITH alarmas_recientes AS (
    -- Total de alarmas en últimos 30 días
    SELECT COUNT(*) AS total_alarmas
    FROM alarmas
    WHERE fecha_alarma >= NOW() - INTERVAL '30 days'
),
conteo_por_tipo AS (
    -- Conteo de alarmas por tipo en últimos 30 días
    SELECT
        tipoalarma_id,
        COUNT(*) AS cantidad_ultimo_mes
    FROM alarmas
    WHERE fecha_alarma >= NOW() - INTERVAL '30 days'
    GROUP BY tipoalarma_id
)
SELECT
    ta.tipoalarma_id,
    ta.descripciontipoalarma,
    ta.short_alias,
    ta.icono,
    ta.radio_interes_metros,
    ta.minutos_vigencia,
    ta.color_fondo_feed,
    COALESCE(cpt.cantidad_ultimo_mes, 0) AS cantidad_ultimo_mes,
    COALESCE(
        ROUND(
            (cpt.cantidad_ultimo_mes::NUMERIC / NULLIF(ar.total_alarmas, 0)::NUMERIC) * 100,
            1
        ),
        0.0
    ) AS porcentaje_ultimo_mes,
    ta.visible_en_app_android,
    ta.visible_en_app_ios,
    ta.requiere_mensaje_advertencia_android,
    ta.requiere_mensaje_advertencia_ios
FROM tipoalarma ta
CROSS JOIN alarmas_recientes ar
LEFT JOIN conteo_por_tipo cpt ON ta.tipoalarma_id = cpt.tipoalarma_id
ORDER BY porcentaje_ultimo_mes DESC, ta.tipoalarma_id ASC;


COMMENT ON VIEW public.vw_tipoalarma_estadistica_30d IS
'Vista de estadísticas de tipos de alarma en los últimos 30 días. Calcula porcentaje de participación global por tipo de alarma. Fecha: 2025-12-20. Referencia: ManualGeneralSOSpect.md [CAMBIO - 19-12-2025 14:00]';
