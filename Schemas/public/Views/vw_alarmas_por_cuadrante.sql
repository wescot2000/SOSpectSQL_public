-- View: public.vw_alarmas_por_cuadrante
-- Creado: 23-02-2026
-- Propósito: Vista agregada para el mapa dinámico. Agrupa alarmas activas en cuadrantes
-- geográficos de ~1.1km (0.01 grado ≈ 1.1km) para clustering visual en el mapa.
-- Se usa cuando el usuario aleja el zoom del mapa y el MAUI llama al endpoint ObtenerAlarmasPorZona
-- con el bounding box de la región visible.

-- DROP VIEW IF EXISTS public.vw_alarmas_por_cuadrante;

CREATE OR REPLACE VIEW public.vw_alarmas_por_cuadrante
 AS
SELECT
    ROUND(al.latitud::numeric, 2) AS lat_cuadrante,
    ROUND(al.longitud::numeric, 2) AS lng_cuadrante,
    al.tipoalarma_id,
    ta.descripciontipoalarma,
    ta.color_fondo_feed,
    COUNT(*) AS cantidad_alarmas,
    MAX(al.fecha_alarma) AS ultima_alarma
FROM public.alarmas al
JOIN public.tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
WHERE
    al.estado_alarma IS NULL  -- alarmas activas
    OR (al.estado_alarma = 'C' AND al.fecha_alarma > NOW() - INTERVAL '90 minutes')  -- cerradas recientes
GROUP BY
    ROUND(al.latitud::numeric, 2),
    ROUND(al.longitud::numeric, 2),
    al.tipoalarma_id,
    ta.descripciontipoalarma,
    ta.color_fondo_feed;


COMMENT ON VIEW public.vw_alarmas_por_cuadrante IS
'Vista de alarmas agrupadas en cuadrantes geográficos (~1.1km) para clustering en el mapa. Consumida por el endpoint ObtenerAlarmasPorZona al alejar el zoom del mapa.';
