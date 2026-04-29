-- View: public.vw_cantidad_alarmas_zona
-- Rediseno con PostGIS ST_DWithin para filtrado de proximidad preciso en metros.
-- Cuenta alarmas activas de SEGURIDAD/POLITICA dentro del radio del usuario.
-- Usa notificaciones_persona como filtro anti-duplicado (no contar alarmas ya notificadas).
-- Radio efectivo = GREATEST(radio_interes_metros del tipoalarma, radio suscripcion activa, radio default usuario).

-- DROP VIEW IF EXISTS public.vw_cantidad_alarmas_zona;

CREATE OR REPLACE VIEW public.vw_cantidad_alarmas_zona AS
WITH alarmas_criticas AS (
    -- Alarmas activas de categorias SEGURIDAD y POLITICA
    SELECT
        al.alarma_id,
        al.latitud,
        al.longitud,
        COALESCE(ta.radio_interes_metros, 0) AS alarm_radio_mts
    FROM alarmas al
    INNER JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
    INNER JOIN categoria_alarma ca ON ca.categoria_alarma_id = ta.categoria_alarma_id
    WHERE al.estado_alarma IS NULL
      AND ca.nombre IN ('SEGURIDAD', 'POLITICA')
),
conteo_alarmas AS (
    SELECT
        p.persona_id,
        COUNT(DISTINCT ac.alarma_id) AS cantidad
    FROM personas p
    -- Ultima ubicacion tipo P del usuario
    INNER JOIN LATERAL (
        SELECT u.latitud, u.longitud
        FROM ubicaciones u
        WHERE u.persona_id = p.persona_id
          AND u."Tipo" = 'P'
        ORDER BY u.ubicacion_id DESC
        LIMIT 1
    ) ul ON true
    -- Radio por defecto del usuario
    INNER JOIN radio_alarmas ra ON ra.radio_alarmas_id = p.radio_alarmas_id
    -- Suscripcion de ampliacion de radio (si esta activa)
    LEFT JOIN subscripciones s
        ON s.persona_id = p.persona_id
        AND s.radio_alarmas_id IS NOT NULL
        AND now() >= s.fecha_activacion
        AND now() <= COALESCE(s.fecha_finalizacion, now())
    LEFT JOIN radio_alarmas ra_susc
        ON ra_susc.radio_alarmas_id = s.radio_alarmas_id
    -- Alarmas criticas dentro del radio de proximidad (PostGIS ST_DWithin con geography = metros)
    INNER JOIN alarmas_criticas ac
        ON ST_DWithin(
            ST_SetSRID(ST_MakePoint(ul.longitud::float8, ul.latitud::float8), 4326)::geography,
            ST_SetSRID(ST_MakePoint(ac.longitud::float8, ac.latitud::float8), 4326)::geography,
            GREATEST(
                ac.alarm_radio_mts,
                COALESCE(ra_susc.radio_mts, 0),
                ra.radio_mts
            )::float8
        )
    -- Filtro anti-duplicado: excluir alarmas ya notificadas al usuario
    LEFT JOIN notificaciones_persona np
        ON np.persona_id = p.persona_id
        AND np.alarma_id = ac.alarma_id
    WHERE np.notificacion_id IS NULL
    GROUP BY p.persona_id
)
-- Resultado final: incluir TODOS los usuarios (incluso con cantidad=0)
SELECT
    p.user_id_thirdparty,
    d.registrationid,
    COALESCE(ca.cantidad, 0) AS cantidad,
    (SELECT MAX(np2.ultima_notificacion_enviada)
     FROM notificaciones_persona np2
     WHERE np2.persona_id = p.persona_id) AS ultima_notificacion
FROM personas p
LEFT JOIN dispositivos d
    ON d.persona_id = p.persona_id
    AND d.fecha_fin IS NULL
LEFT JOIN conteo_alarmas ca
    ON ca.persona_id = p.persona_id;


COMMENT ON VIEW public.vw_cantidad_alarmas_zona IS
'Vista PostGIS: cuenta alarmas activas de SEGURIDAD/POLITICA dentro del radio de proximidad del usuario.
Radio efectivo = GREATEST(radio_interes_metros del tipoalarma, radio suscripcion activa, radio default usuario).
Usa ST_DWithin(geography) para distancias precisas en metros.
Usa notificaciones_persona como filtro anti-duplicado para no contar alarmas ya notificadas.
Usado por InsertarUbicacion y InsertaUbicacionBackground.';
