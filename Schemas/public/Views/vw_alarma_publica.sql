-- View: public.vw_alarma_publica
-- Propósito: Expone campos seguros de una alarma para el endpoint público /api/public/alert/{id}.
--            No incluye datos personales del creador (persona_id, user_id_thirdparty, login, etc.).
--            Todas las alarmas son accesibles por ID, sin importar estado ni antigüedad,
--            ya que los links compartidos sirven como evidencia permanente de incidentes.
--            TODO futuro: si la alarma fue migrada a S3, buscarla allá.
-- Uso:       SELECT * FROM vw_alarma_publica WHERE alarma_id = @id AND flag_visible_mapa = true

-- DROP VIEW public.vw_alarma_publica;

CREATE OR REPLACE VIEW public.vw_alarma_publica
 AS
SELECT
    al.alarma_id,
    al.fecha_alarma,
    ta.tipoalarma_id,
    ta.descripciontipoalarma,
    COALESCE(
        (
            SELECT da.descripcionalarma
            FROM descripcionesalarmas da
            WHERE da.alarma_id = al.alarma_id
              AND da.descripcionalarma IS NOT NULL
            ORDER BY da.iddescripcion ASC
            LIMIT 1
        ),
        'Sin descripción'
    ) AS Descripcionalarma,
    al.latitud  AS latitud_alarma,
    al.longitud AS longitud_alarma,
    CASE WHEN al.estado_alarma IS NULL THEN true ELSE false END AS EsAlarmaActiva,
    COALESCE(
        (
            SELECT ROUND(
                (COUNT(*) FILTER (WHERE da.veracidadalarma = true)::numeric * 100
                 / NULLIF(COUNT(*), 0)
                ), 2)
            FROM descripcionesalarmas da
            WHERE da.alarma_id = al.alarma_id
        ),
        100.00
    ) AS calificacion_actual_alarma,
    (
        SELECT COUNT(*)
        FROM descripcionesalarmas da
        WHERE da.alarma_id = al.alarma_id
          AND da.veracidadalarma IS NULL
    ) AS cantidad_interacciones,
    atr.barrio,
    atr.ciudad,
    atr.pais,
    -- Siempre true: los links públicos son evidencia permanente del incidente.
    -- Si la alarma migró a S3 en el futuro, esta vista se actualiza para buscarla allá.
    true AS flag_visible_mapa,
    COALESCE(
        (SELECT COUNT(*) FROM alarmas_likes lk WHERE lk.alarma_id = al.alarma_id), 0
    ) AS cantidad_likes,
    COALESCE(
        (SELECT COUNT(*) FROM alarmas_reenvios re WHERE re.alarma_id = al.alarma_id), 0
    ) AS cantidad_reenvios
FROM alarmas al
INNER JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
LEFT JOIN alarmas_territorio atr ON atr.alarma_id = al.alarma_id;

