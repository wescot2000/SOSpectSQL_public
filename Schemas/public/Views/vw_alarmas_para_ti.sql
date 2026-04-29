-- View: public.vw_alarmas_para_ti
-- Vista para feed "Para Ti" con ranking y paginación
-- Fecha: 2025-12-14
-- MODIFICADO: 23-02-2026 - Ampliar retención de alarmas virales de 30 a 120 días
-- MODIFICADO: 2026-02-26 - Usar contadores denormalizados cnt_* de tabla alarmas; agregar filtro por países
-- MODIFICADO: 2026-02-26 - Cambiar filtro paises_feed_filtro de nombres completos a ISO alpha-2 usando JOIN con tabla paises
-- MODIFICADO: 2026-03-09 - Agregar categoria_alarma_id desde tipoalarma (usado en MAUI para botón "Ver autoridades")
-- MODIFICADO: 2026-03-29 - Agregar tiene_votacion_activa y usuario_ya_voto para cierre por encuesta
-- MODIFICADO: 2026-04-18 - Agregar tipo_cierre (de tipoalarma) en los 3 CTEs y SELECT final para enrutamiento de pantalla de cierre

-- DROP VIEW IF EXISTS public.vw_alarmas_para_ti;

CREATE OR REPLACE VIEW public.vw_alarmas_para_ti
 AS
 WITH
AlarmasSeguridad AS (
    SELECT DISTINCT ON (al.alarma_id, p.user_id_thirdparty)
        p.user_id_thirdparty,
        p.persona_id,
        alper.user_id_thirdparty AS user_id_creador_alarma,
        al.alarma_id,
        al.fecha_alarma,
        al.estado_alarma,
        al.latitud AS latitud_alarma,
        al.longitud AS longitud_alarma,
        u.latitud AS latitud_usuario,
        u.longitud AS longitud_usuario,
        ta.tipoalarma_id,
        ta.categoria_alarma_id,
        ta.descripciontipoalarma,
        ta.minutos_vigencia,
        ta.color_fondo_feed,
        ta.tipo_cierre,
        al.calificacion_alarma AS credibilidad_alarma,
        ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
        coalesce(alper.flag_red_confianza, FALSE) as flag_red_confianza,
        dis.idioma,
        dis.registrationid,
        COALESCE(ta.radio_interes_metros, ra.radio_mts) AS radio_interes_metros,
        CASE
            WHEN p.user_id_thirdparty::text = alper.user_id_thirdparty::text THEN true
            ELSE false
        END AS flag_propietario_alarma,
        ts.descripcion_tipo AS tipo_subscr_activa_usuario,
        true AS flag_seguridad_personal,
        0 AS ranking_relevancia
    FROM ubicaciones u
    JOIN personas p ON p.persona_id = u.persona_id AND u."Tipo"::text = 'P'::text
    JOIN radio_alarmas ra ON ra.radio_alarmas_id = p.radio_alarmas_id
    JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
    JOIN alarmas al ON
        al.latitud >= (u.latitud - 0.090000) AND
        al.latitud <= (u.latitud + 0.090000) AND
        al.longitud >= (u.longitud - 0.090000) AND
        al.longitud <= (u.longitud + 0.090000)
    JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
    JOIN personas alper ON alper.persona_id = al.persona_id
    LEFT JOIN subscripciones s ON s.persona_id = p.persona_id
        AND now() >= s.fecha_activacion
        AND now() <= COALESCE(s.fecha_finalizacion, now())
    LEFT JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
    LEFT JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida
        AND p.persona_id = rp.id_persona_protector
        AND now() >= rp.fecha_activacion
        AND now() <= COALESCE(rp.fecha_finalizacion, now())
    WHERE
        p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
        AND
        (
            (
                ta.radio_interes_metros IS NOT NULL AND
                ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) <= ta.radio_interes_metros
            )
            OR
            (
                ta.radio_interes_metros IS NULL AND
                ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) <= ra.radio_mts
            )
            OR
            (rp.id_rel_protegido IS NOT NULL)
            OR
            (ts.descripcion_tipo = 'Zona de vigilancia adicional')
        )
        AND
        p.notif_alarma_cercana_habilitada IS TRUE

    UNION ALL

    SELECT DISTINCT ON (al.alarma_id, p.user_id_thirdparty)
        p.user_id_thirdparty,
        p.persona_id,
        alper.user_id_thirdparty AS user_id_creador_alarma,
        al.alarma_id,
        al.fecha_alarma,
        al.estado_alarma,
        al.latitud AS latitud_alarma,
        al.longitud AS longitud_alarma,
        u.latitud AS latitud_usuario,
        u.longitud AS longitud_usuario,
        ta.tipoalarma_id,
        ta.categoria_alarma_id,
        ta.descripciontipoalarma,
        ta.minutos_vigencia,
        ta.color_fondo_feed,
        ta.tipo_cierre,
        al.calificacion_alarma AS credibilidad_alarma,
        0 AS distancia_en_metros,
        coalesce(alper.flag_red_confianza, FALSE) as flag_red_confianza,
        dis.idioma,
        dis.registrationid,
        COALESCE(ta.radio_interes_metros, ra.radio_mts) AS radio_interes_metros,
        true AS flag_propietario_alarma,
        NULL::character varying AS tipo_subscr_activa_usuario,
        true AS flag_seguridad_personal,
        0 AS ranking_relevancia
    FROM ubicaciones u
    JOIN personas p ON p.persona_id = u.persona_id AND u."Tipo"::text = 'P'::text
    JOIN radio_alarmas ra ON ra.radio_alarmas_id = p.radio_alarmas_id
    JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
    JOIN alarmas al ON al.persona_id = p.persona_id
    JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
    JOIN personas alper ON alper.persona_id = al.persona_id
),
AlarmasVirales AS (
    SELECT
        p.user_id_thirdparty,
        p.persona_id,
        alper.user_id_thirdparty AS user_id_creador_alarma,
        al.alarma_id,
        al.fecha_alarma,
        al.estado_alarma,
        al.latitud AS latitud_alarma,
        al.longitud AS longitud_alarma,
        u.latitud AS latitud_usuario,
        u.longitud AS longitud_usuario,
        ta.tipoalarma_id,
        ta.categoria_alarma_id,
        ta.descripciontipoalarma,
        ta.minutos_vigencia,
        ta.color_fondo_feed,
        ta.tipo_cierre,
        al.calificacion_alarma AS credibilidad_alarma,
        ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
        coalesce(alper.flag_red_confianza, FALSE) as flag_red_confianza,
        dis.idioma,
        dis.registrationid,
        COALESCE(ta.radio_interes_metros, ra.radio_mts) AS radio_interes_metros,
        CASE
            WHEN p.user_id_thirdparty::text = alper.user_id_thirdparty::text THEN true
            ELSE false
        END AS flag_propietario_alarma,
        NULL::character varying AS tipo_subscr_activa_usuario,
        false AS flag_seguridad_personal,
        -- MODIFICADO 2026-02-26: Usar contadores denormalizados cnt_* en lugar de COUNT
        (
            COALESCE(multimedia.cantidad_videos, 0) * 1.5 +
            COALESCE(multimedia.cantidad_fotos, 0) * 1.3 +
            COALESCE(interacciones.cantidad_interacciones, 0) * 1.2 +
            al.cnt_likes * 1.4 +
            al.cnt_reenvios * 1.6
        ) *
        CASE
            WHEN al.estado_alarma IS NULL THEN 1.5
            ELSE 1.0
        END AS ranking_relevancia
    FROM ubicaciones u
    JOIN personas p ON p.persona_id = u.persona_id AND u."Tipo"::text = 'P'::text
    JOIN radio_alarmas ra ON ra.radio_alarmas_id = p.radio_alarmas_id
    JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
    JOIN alarmas al ON
        al.latitud >= (u.latitud - 0.090000) AND
        al.latitud <= (u.latitud + 0.090000) AND
        al.longitud >= (u.longitud - 0.090000) AND
        al.longitud <= (u.longitud + 0.090000)
    JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
    JOIN personas alper ON alper.persona_id = al.persona_id
    -- Para filtro de países: obtener el país de la alarma desde alarmas_territorio
    LEFT JOIN alarmas_territorio aterr ON aterr.alarma_id = al.alarma_id
    LEFT JOIN (
        SELECT
            da.alarma_id,
            COUNT(DISTINCT CASE WHEN fda.es_video = true THEN fda.foto_id END) AS cantidad_videos,
            COUNT(DISTINCT CASE WHEN fda.es_video = false THEN fda.foto_id END) AS cantidad_fotos
        FROM descripcionesalarmas da
        LEFT JOIN fotos_descripciones_alarmas fda ON fda.iddescripcion = da.iddescripcion AND fda.estado = 'A'
        GROUP BY da.alarma_id
    ) multimedia ON multimedia.alarma_id = al.alarma_id
    LEFT JOIN (
        SELECT
            alarma_id,
            COUNT(*) AS cantidad_interacciones
        FROM descripcionesalarmas
        WHERE descripcionalarma IS NOT NULL
          AND veracidadalarma IS NULL
        GROUP BY alarma_id
    ) interacciones ON interacciones.alarma_id = al.alarma_id
    WHERE
        al.fecha_alarma > NOW() - INTERVAL '120 days'
        AND
        al.alarma_id NOT IN (SELECT alarma_id FROM AlarmasSeguridad WHERE user_id_thirdparty = p.user_id_thirdparty)
        AND
        p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
        -- FILTRO DE PAÍSES: Si el usuario tiene paises_feed_filtro (ISO alpha-2), resolver nombre via JOIN con paises
        -- paises_feed_filtro contiene ISO alpha-2 (ej: ['CO','MX']); alarmas_territorio.pais tiene nombre completo
        AND (
            p.paises_feed_filtro IS NULL
            OR EXISTS (
                SELECT 1 FROM public.paises pa2
                WHERE pa2.pais_id = ANY(p.paises_feed_filtro)
                AND aterr.pais ILIKE pa2.nombre_es
            )
        )
),
FotosAlarma AS (
    SELECT
        f.foto_id,
        da.alarma_id,
        f.url_foto,
        f.thumbnail_url,
        f.nombre_archivo_original,
        f.tipo_mime,
        f.es_video,
        f.tamano_bytes,
        f.ancho_pixels,
        f.alto_pixels,
        f.orden,
        f.fecha_subida,
        ROW_NUMBER() OVER (PARTITION BY da.alarma_id ORDER BY da.fechadescripcion ASC, f.orden ASC, f.fecha_subida ASC) AS rn
    FROM fotos_descripciones_alarmas f
    JOIN descripcionesalarmas da ON f.iddescripcion = da.iddescripcion
    WHERE f.estado = 'A'
),
FotosAgregadas AS (
    SELECT
        alarma_id,
        json_agg(
            json_build_object(
                'foto_id', foto_id,
                'url_foto', url_foto,
                'thumbnail_url', thumbnail_url,
                'nombre_archivo_original', nombre_archivo_original,
                'tipo_mime', tipo_mime,
                'es_video', es_video,
                'tamano_bytes', tamano_bytes,
                'ancho_pixels', ancho_pixels,
                'alto_pixels', alto_pixels,
                'orden', orden,
                'fecha_subida', fecha_subida
            ) ORDER BY rn
        ) AS fotos_json
    FROM FotosAlarma
    WHERE rn <= 5
    GROUP BY alarma_id
),
AlarmasCombinadas AS (
    SELECT * FROM AlarmasSeguridad
    UNION ALL
    SELECT * FROM AlarmasVirales
)
SELECT
    ac.user_id_thirdparty,
    ac.persona_id,
    ac.latitud_alarma,
    ac.longitud_alarma,
    ac.user_id_creador_alarma,
    CASE
        WHEN LENGTH(ac.user_id_creador_alarma) > 7 THEN
            SUBSTRING(ac.user_id_creador_alarma, 1, 3) || '-' ||
            SUBSTRING(ac.user_id_creador_alarma, LENGTH(ac.user_id_creador_alarma) - 3, 4)
        ELSE ac.user_id_creador_alarma
    END AS usuario_anonimizado,
    ac.alarma_id,
    ac.fecha_alarma,
    ac.estado_alarma,
    ac.idioma AS idioma_destino,
    ac.tipoalarma_id,
    ac.categoria_alarma_id,
    ac.descripciontipoalarma,
    ac.minutos_vigencia,
    ac.color_fondo_feed,
    ac.credibilidad_alarma,
    ac.distancia_en_metros,
    ac.flag_red_confianza,
    ac.registrationid,
    ac.radio_interes_metros,
    ac.flag_propietario_alarma,
    ac.tipo_subscr_activa_usuario,
    ac.flag_seguridad_personal,
    ac.ranking_relevancia,
    ac.tipo_cierre,
    COALESCE(fa.fotos_json, '[]'::json) AS fotos_alarma,
    CASE
        WHEN ac.flag_red_confianza IS TRUE THEN
            'URGENTE RED DE CONFIANZA: ' || ac.descripciontipoalarma ||
            ' a ' || ac.distancia_en_metros || ' metros. Veracidad: ' ||
            ac.credibilidad_alarma || '%'
        ELSE
            ac.descripciontipoalarma || ' a ' || ac.distancia_en_metros ||
            ' metros de ti. Veracidad: ' || ac.credibilidad_alarma || '%'
    END AS txt_notif,
    -- VOTACIÓN DE CIERRE COMUNITARIO (2026-03-29)
    -- tiene_votacion_activa: TRUE si la alarma tiene una solicitud de cierre activa (aún en período de votación)
    COALESCE(sc_activa.solicitud_id IS NOT NULL, FALSE) AS tiene_votacion_activa,
    -- usuario_ya_voto: TRUE si el usuario consultante ya emitió su voto en la solicitud activa
    COALESCE(vc_usuario.voto_id IS NOT NULL, FALSE) AS usuario_ya_voto
FROM AlarmasCombinadas ac
LEFT JOIN FotosAgregadas fa ON ac.alarma_id = fa.alarma_id
-- JOINs para votación de cierre comunitario (2026-03-29)
LEFT JOIN solicitudes_cierre sc_activa
    ON sc_activa.alarma_id = ac.alarma_id
   AND sc_activa.estado = 'activa'
LEFT JOIN votos_cierre vc_usuario
    ON vc_usuario.solicitud_id = sc_activa.solicitud_id
   AND vc_usuario.persona_id = ac.persona_id
ORDER BY
    CASE WHEN ac.flag_seguridad_personal THEN 0 ELSE 1 END,
    ac.ranking_relevancia DESC,
    ac.fecha_alarma DESC,
    ac.alarma_id DESC;

