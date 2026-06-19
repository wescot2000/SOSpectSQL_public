-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- View: public.vw_feed_para_ti
-- Vista del feed NACIONAL "Para Ti" (pestaña "Para Ti" de DescribirPage).
-- Clon de vw_alarmas_completa con DOS diferencias clave:
--   1. SIN radio geográfico: el feed "Para Ti" es nacional/multipaís, no por cercanía.
--      Se elimina el JOIN radio_alarmas ra_busqueda y las condiciones de bounding-box
--      sobre al.latitud/al.longitud. Cada alarma del país seleccionado es candidata.
--   2. Filtro por país (ISO alpha-2) con bypass de seguridad personal:
--      Las alarmas propias, de protegidos y de la red de confianza SIEMPRE son visibles,
--      ignorando el filtro de país. El resto se filtra por personas.paises_feed_filtro.
--      Si paises_feed_filtro es NULL (== "Todos"), no se aplica filtro de país.
--
-- Nota de retención: la ETL archiva diariamente a S3 y borra alarmas > ~120 días,
-- por lo que NO se necesita ventana de fecha en la vista.
--
-- IMPORTANTE: las columnas son IDÉNTICAS a vw_alarmas_completa (más pais_id al final),
-- para que el reader de ObtenerFeedParaTi y el modelo MAUI no requieran cambios.
-- Fecha: 2026-06-04

-- DROP VIEW IF EXISTS public.vw_feed_para_ti;

CREATE OR REPLACE VIEW public.vw_feed_para_ti
 AS
 SELECT
    p.user_id_thirdparty,
    p.persona_id,
    alper.user_id_thirdparty AS user_id_creador_alarma,
    CASE
        WHEN LENGTH(alper.user_id_thirdparty) > 7 THEN
            SUBSTRING(alper.user_id_thirdparty, 1, 3) || '-' ||
            SUBSTRING(alper.user_id_thirdparty, LENGTH(alper.user_id_thirdparty) - 3, 4)
        ELSE alper.user_id_thirdparty
    END AS usuario_anonimizado,
    p.login AS login_usuario_notificar,
    al.latitud AS latitud_alarma,
    al.longitud AS longitud_alarma,
    u.latitud AS latitud_entrada,
    u.longitud AS longitud_entrada,
    COALESCE(ts.descripcion_tipo, 'Ninguna') AS tipo_subscr_activa_usuario,
    s.fecha_activacion AS fecha_activacion_subscr,
    s.fecha_finalizacion AS fecha_finalizacion_subscr,
    ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
    al.alarma_id,
    al.fecha_alarma,
    ta.descripciontipoalarma,
    ta.tipoalarma_id,
    ta.color_fondo_feed,
    60::smallint AS tiemporefrescoubicacion,
    CASE
        WHEN p.user_id_thirdparty::text = alper.user_id_thirdparty::text THEN true
        ELSE false
    END AS flag_propietario_alarma,
    COALESCE((((verdaderos.cantidad_verdadero * 100)::numeric(18,2) / total.cantidad_total::numeric(18,2))::numeric(18,2) * (alper.credibilidad_persona / 100::numeric)::numeric(18,2))::numeric(5,2), 100.00) AS calificacion_actual_alarma,
    CASE
        WHEN dal.veracidadalarma IS NOT NULL THEN 1::boolean
        ELSE 0::boolean
    END AS usuariocalificoalarma,
    CASE
        WHEN dal.veracidadalarma = true THEN 'Verdadero'::character varying(15)
        WHEN dal.veracidadalarma = false THEN 'Negativo'::character varying(15)
        ELSE 'Apagado'::character varying(15)
    END AS calificacionalarmausuario,
    CASE WHEN al.estado_alarma IS NULL THEN true ELSE false END AS esalarmaactiva,
    al.alarma_id_padre,
    al.calificacion_alarma,
    CASE WHEN al.estado_alarma IS NULL THEN true ELSE false END AS estado_alarma,
    COALESCE(dal.flag_hubo_captura, false) AS flag_hubo_captura,
    CASE WHEN (SELECT count(*) FROM atencion_policiaca ap WHERE ap.alarma_id = al.alarma_id) > 0 THEN true ELSE false END AS flag_alarma_siendo_atendida,
    (SELECT count(*) FROM atencion_policiaca ap WHERE ap.alarma_id = al.alarma_id) AS cantidad_agentes_atendiendo,
    (SELECT count(*) FROM descripcionesalarmas dalt WHERE dalt.alarma_id = al.alarma_id AND dalt.veracidadalarma IS NULL) AS cantidad_interacciones,
    p.flag_es_policia,
    CAST(descr.descripcionalarma AS varchar(500)) AS descripcionalarma,
    COALESCE(alper.flag_red_confianza, false) AS flag_red_confianza,
    ra_usuario.radio_mts AS radio_alarmas_mts_actual,
    COALESCE(ta.radio_interes_metros, ra_usuario.radio_mts) AS radio_interes_metros,
    ta.minutos_vigencia,
    ta.tipo_cierre,
    COALESCE(multimedia.cantidad_videos, 0) AS cantidad_videos,
    COALESCE(multimedia.cantidad_fotos, 0) AS cantidad_fotos,
    CASE
        WHEN p.user_id_thirdparty::text = alper.user_id_thirdparty::text THEN true
        WHEN rp.id_rel_protegido IS NOT NULL THEN true
        WHEN alper.flag_red_confianza IS TRUE THEN true
        ELSE false
    END AS flag_seguridad_personal,
    (
        COALESCE(multimedia.cantidad_videos, 0) * 1.5 +
        COALESCE(multimedia.cantidad_fotos, 0) * 1.3 +
        COALESCE((SELECT count(*) FROM descripcionesalarmas dalt WHERE dalt.alarma_id = al.alarma_id AND dalt.veracidadalarma IS NULL), 0) * 1.2
    ) *
    CASE
        WHEN al.estado_alarma IS NULL THEN 1.5
        ELSE 1.0
    END AS ranking_relevancia,
    CASE
        WHEN al.estado_alarma IS NULL THEN true
        WHEN al.estado_alarma IS NOT NULL AND al.fecha_alarma > NOW() - interval '90 minutes' THEN true
        ELSE false
    END AS flag_visible_mapa,
    CASE
        WHEN al.estado_alarma IS NULL THEN true
        WHEN al.estado_alarma IS NOT NULL AND al.fecha_alarma > NOW() - interval '90 minutes' THEN true
        WHEN ps_seguido.seguimiento_id IS NOT NULL THEN true
        WHEN re_seguido.reenvio_id IS NOT NULL THEN true
        ELSE false
    END AS flag_visible_siguiendo,
    COALESCE(fotos_agg.fotos_json, '[]'::json) AS fotos_alarma,
    false AS pendiente_sincronizacion,
    aterr.barrio,
    aterr.ciudad,
    aterr.pais,
    al.cnt_likes AS cantidad_likes,
    CASE WHEN lk_usuario.like_id IS NOT NULL THEN true ELSE false END AS usuario_dio_like,
    al.cnt_reenvios AS cantidad_reenvios,
    CASE WHEN re_usuario.reenvio_id IS NOT NULL THEN true ELSE false END AS usuario_reenvio,
    al.cnt_verdaderos AS cantidad_verdaderos,
    al.cnt_falsos AS cantidad_falsos,
    CASE WHEN re_reenvio.reenvio_id IS NOT NULL THEN true ELSE false END AS flag_es_reenvio,
    CASE
        WHEN re_reenvio.reenvio_id IS NOT NULL THEN
            CASE
                WHEN LENGTH(per_reenvio.user_id_thirdparty) > 7 THEN
                    SUBSTRING(per_reenvio.user_id_thirdparty, 1, 3) || '-' ||
                    SUBSTRING(per_reenvio.user_id_thirdparty, LENGTH(per_reenvio.user_id_thirdparty) - 3, 4)
                ELSE per_reenvio.user_id_thirdparty
            END
        ELSE NULL
    END AS reenvio_user_id_anonimizado,
    COALESCE(ta.is_advertising, FALSE) AS is_advertising,
    subs_pub.radio_metros AS publicidad_radio_metros,
    COALESCE(subs_pub.logo_habilitado, FALSE) AS publicidad_logo_habilitado,
    subs_pub.url_logo AS publicidad_url_logo,
    COALESCE(subs_pub.contacto_habilitado, FALSE) AS publicidad_contacto_habilitado,
    COALESCE(subs_pub.domicilio_habilitado, FALSE) AS publicidad_domicilio_habilitado,
    subs_pub.texto_push_personalizado AS publicidad_texto_push,
    subs_pub.nombre_emprendimiento AS publicidad_nombre_emprendimiento,
    COALESCE(sc_activa.solicitud_id IS NOT NULL, FALSE) AS tiene_votacion_activa,
    COALESCE(vc_usuario.voto_id IS NOT NULL, FALSE) AS usuario_ya_voto,
    -- NUEVO 2026-06-04: ISO alpha-2 del país de la alarma (para filtro del feed nacional)
    aterr.pais_id
FROM ubicaciones u
JOIN personas p ON p.persona_id = u.persona_id AND u."Tipo"::text = 'P'::text
JOIN radio_alarmas ra_usuario ON ra_usuario.radio_alarmas_id = p.radio_alarmas_id
-- SIN radio de búsqueda: feed nacional. Cada alarma es candidata (sin bounding-box).
JOIN alarmas al ON TRUE
JOIN personas alper ON alper.persona_id = al.persona_id
JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
LEFT JOIN subscripciones s ON s.persona_id = p.persona_id
    AND s.radio_alarmas_id IS NOT NULL
    AND now() >= s.fecha_activacion
    AND now() <= COALESCE(s.fecha_finalizacion, now())
LEFT JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
LEFT JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida
    AND p.persona_id = rp.id_persona_protector
    AND now() >= rp.fecha_activacion
    AND now() <= COALESCE(rp.fecha_finalizacion, now())
LEFT JOIN descripcionesalarmas dal ON dal.alarma_id = al.alarma_id AND dal.persona_id = p.persona_id AND dal.veracidadalarma IS NOT NULL
LEFT JOIN (
    SELECT al_1.alarma_id,
        CASE WHEN count(*) = 0 THEN 1::bigint ELSE count(*) END AS cantidad_verdadero
    FROM alarmas al_1
    LEFT JOIN descripcionesalarmas da ON al_1.alarma_id = da.alarma_id AND da.veracidadalarma = true
    WHERE al_1.estado_alarma IS NULL
    GROUP BY al_1.alarma_id
) verdaderos ON al.alarma_id = verdaderos.alarma_id
LEFT JOIN (
    SELECT al_1.alarma_id,
        CASE WHEN count(*) = 0 THEN 1::bigint ELSE count(*) END AS cantidad_total
    FROM alarmas al_1
    LEFT JOIN descripcionesalarmas da ON al_1.alarma_id = da.alarma_id
    WHERE al_1.estado_alarma IS NULL
    GROUP BY al_1.alarma_id
) total ON al.alarma_id = total.alarma_id
LEFT JOIN (
    SELECT al_1.alarma_id,
        COALESCE(
            (SELECT da.descripcionalarma FROM descripcionesalarmas da
             WHERE da.alarma_id = al_1.alarma_id AND da.descripcionalarma IS NOT NULL
             ORDER BY da.iddescripcion ASC LIMIT 1),
            (SELECT da_padre.descripcionalarma FROM descripcionesalarmas da_padre
             WHERE da_padre.alarma_id = al_1.alarma_id_padre AND da_padre.descripcionalarma IS NOT NULL
             ORDER BY da_padre.iddescripcion ASC LIMIT 1),
            'Sin descripción por el momento'
        ) AS descripcionalarma
    FROM alarmas al_1
) descr ON al.alarma_id = descr.alarma_id
LEFT JOIN (
    SELECT da.alarma_id,
        COUNT(DISTINCT CASE WHEN fda.es_video = true THEN fda.foto_id END) AS cantidad_videos,
        COUNT(DISTINCT CASE WHEN fda.es_video = false THEN fda.foto_id END) AS cantidad_fotos
    FROM descripcionesalarmas da
    LEFT JOIN fotos_descripciones_alarmas fda ON fda.iddescripcion = da.iddescripcion AND fda.estado = 'A'
    GROUP BY da.alarma_id
) multimedia ON multimedia.alarma_id = al.alarma_id
LEFT JOIN (
    SELECT fa.alarma_id,
        json_agg(
            json_build_object(
                'foto_id', fa.foto_id,
                'url_foto', fa.url_foto,
                'thumbnail_url', fa.thumbnail_url,
                'nombre_archivo_original', fa.nombre_archivo_original,
                'tipo_mime', fa.tipo_mime,
                'es_video', fa.es_video,
                'tamano_bytes', fa.tamano_bytes,
                'ancho_pixels', fa.ancho_pixels,
                'alto_pixels', fa.alto_pixels,
                'orden', fa.orden,
                'fecha_subida', fa.fecha_subida
            ) ORDER BY fa.rn
        ) AS fotos_json
    FROM (
        SELECT f.foto_id, da.alarma_id, f.url_foto, f.thumbnail_url,
               f.nombre_archivo_original, f.tipo_mime, f.es_video,
               f.tamano_bytes, f.ancho_pixels, f.alto_pixels, f.orden, f.fecha_subida,
               ROW_NUMBER() OVER (PARTITION BY da.alarma_id ORDER BY da.fechadescripcion ASC, f.orden ASC, f.fecha_subida ASC) AS rn
        FROM fotos_descripciones_alarmas f
        JOIN descripcionesalarmas da ON f.iddescripcion = da.iddescripcion
        WHERE f.estado = 'A'
    ) fa
    WHERE fa.rn <= 5
    GROUP BY fa.alarma_id
) fotos_agg ON fotos_agg.alarma_id = al.alarma_id
LEFT JOIN alarmas_territorio aterr ON aterr.alarma_id = al.alarma_id
LEFT JOIN public.alarmas_likes lk_usuario ON lk_usuario.alarma_id = al.alarma_id AND lk_usuario.persona_id = p.persona_id
LEFT JOIN public.alarmas_reenvios re_usuario ON re_usuario.alarma_id = al.alarma_id AND re_usuario.persona_id = p.persona_id
LEFT JOIN public.alarmas_reenvios re_reenvio ON re_reenvio.alarma_id = al.alarma_id
    AND re_reenvio.persona_id IN (SELECT seguido_persona_id FROM public.personas_seguidores WHERE seguidor_persona_id = p.persona_id)
LEFT JOIN public.personas per_reenvio ON per_reenvio.persona_id = re_reenvio.persona_id
LEFT JOIN public.personas_seguidores ps_seguido ON ps_seguido.seguidor_persona_id = p.persona_id
    AND ps_seguido.seguido_persona_id = alper.persona_id
LEFT JOIN public.alarmas_reenvios re_seguido ON re_seguido.alarma_id = al.alarma_id
    AND re_seguido.persona_id IN (SELECT seguido_persona_id FROM public.personas_seguidores WHERE seguidor_persona_id = p.persona_id)
LEFT JOIN solicitudes_cierre sc_activa
    ON sc_activa.alarma_id = al.alarma_id
   AND sc_activa.estado = 'activa'
LEFT JOIN votos_cierre vc_usuario
    ON vc_usuario.solicitud_id = sc_activa.solicitud_id
   AND vc_usuario.persona_id = p.persona_id
LEFT JOIN (
    SELECT
        s2.subscripcion_id,
        s2.alarma_id,
        s2.radio_metros,
        s2.logo_habilitado,
        e2.url_logo,
        s2.contacto_habilitado,
        s2.domicilio_habilitado,
        s2.fecha_finalizacion,
        s2.texto_push_personalizado,
        e2.nombre_emprendimiento
    FROM subscripciones s2
    LEFT JOIN emprendimientos e2 ON s2.id_emprendimiento = e2.id_emprendimiento
      AND e2.fecha_fin IS NULL
    WHERE s2.alarma_id IS NOT NULL
      AND s2.fecha_finalizacion >= NOW()
) subs_pub ON subs_pub.alarma_id = al.alarma_id
-- ── FILTRO DE PAÍS DEL FEED NACIONAL "Para Ti" con bypass de seguridad personal ──
-- Las alarmas propias, de protegidos y de la red de confianza SIEMPRE son visibles.
-- El resto se filtra por personas.paises_feed_filtro (array ISO alpha-2).
-- Si paises_feed_filtro es NULL ("Todos"), no se aplica filtro de país.
WHERE (
    p.user_id_thirdparty::text = alper.user_id_thirdparty::text   -- alarma propia
    OR rp.id_rel_protegido IS NOT NULL                            -- protegido
    OR alper.flag_red_confianza IS TRUE                           -- red de confianza
    OR p.paises_feed_filtro IS NULL                               -- "Todos": sin filtro
    OR aterr.pais_id = ANY(p.paises_feed_filtro)                  -- país en el filtro (ISO)
)
ORDER BY
    CASE
        WHEN p.user_id_thirdparty::text = alper.user_id_thirdparty::text THEN 0
        WHEN rp.id_rel_protegido IS NOT NULL THEN 0
        WHEN alper.flag_red_confianza IS TRUE THEN 0
        ELSE 1
    END,
    (
        COALESCE(multimedia.cantidad_videos, 0) * 1.5 +
        COALESCE(multimedia.cantidad_fotos, 0) * 1.3 +
        COALESCE((SELECT count(*) FROM descripcionesalarmas dalt WHERE dalt.alarma_id = al.alarma_id AND dalt.veracidadalarma IS NULL), 0) * 1.2
    ) *
    CASE
        WHEN al.estado_alarma IS NULL THEN 1.5
        ELSE 1.0
    END DESC,
    al.fecha_alarma DESC,
    al.alarma_id DESC;


