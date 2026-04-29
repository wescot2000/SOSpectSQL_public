-- Vista: vw_pines_mapa
-- Propósito: Provee los datos necesarios para pintar alarmas en el mapa con todos sus badges
--            e InfoWindow (tipo, distancia, interacciones, policía, red de confianza, creador).
--            Universo: alarmas activas + alarmas cerradas en los últimos 90 minutos.
-- Creada:    2026-03-01 — Rediseño Viewport-Driven del mapa
-- Modificado: 2026-03-02 — Enriquecida con campos sociales para igualar nivel visual de Cache B
--             Se agregaron JOINs con tipoalarma y personas, y subqueries inline
--             para flag_alarma_siendo_atendida, cantidad_interacciones y descripcionalarma.
--             La distancia_en_metros NO está en la vista (depende del usuario consultante);
--             se calcula en el endpoint GET /Ubicaciones/PinesMapa con @userLat/@userLon.
-- Modificado: 2026-03-19 — Agregado alarma_id_padre (col 11) para que PinesMapa pueda
--             dibujar la polyline entre pin hijo (sospechoso huyendo, tipo 9) y pin padre.
-- Usada por: GET /Ubicaciones/PinesMapa

CREATE OR REPLACE VIEW public.vw_pines_mapa AS
SELECT
    al.alarma_id,                                                                           -- col 0
    al.latitud,                                                                             -- col 1
    al.longitud,                                                                            -- col 2
    al.tipoalarma_id,                                                                       -- col 3
    CASE WHEN al.estado_alarma IS NULL THEN true ELSE false END AS estado_alarma,           -- col 4
    -- estado_alarma: true = activa (pin con color por tipo), false = cerrada reciente (pin gris)
    ta.descripciontipoalarma,                                                               -- col 5
    CASE
        WHEN (SELECT count(*) FROM atencion_policiaca ap WHERE ap.alarma_id = al.alarma_id) > 0
        THEN true ELSE false
    END AS flag_alarma_siendo_atendida,                                                     -- col 6
    (SELECT count(*) FROM descripcionesalarmas dalt
     WHERE dalt.alarma_id = al.alarma_id AND dalt.veracidadalarma IS NULL
    ) AS cantidad_interacciones,                                                            -- col 7 (int8)
    COALESCE(alper.flag_red_confianza, false) AS flag_red_confianza,                        -- col 8
    alper.user_id_thirdparty AS user_id_creador_alarma,                                     -- col 9
    (SELECT da.descripcionalarma FROM descripcionesalarmas da
     WHERE da.alarma_id = al.alarma_id AND da.descripcionalarma IS NOT NULL
     ORDER BY da.iddescripcion ASC LIMIT 1) AS descripcionalarma,                          -- col 10
    al.alarma_id_padre                                                                      -- col 11 (nullable)
FROM public.alarmas al
JOIN public.tipoalarma ta   ON ta.tipoalarma_id = al.tipoalarma_id
JOIN public.personas  alper ON alper.persona_id  = al.persona_id
WHERE
    al.estado_alarma IS NULL
    OR (al.estado_alarma IS NOT NULL AND al.fecha_alarma > NOW() - INTERVAL '90 minutes');
