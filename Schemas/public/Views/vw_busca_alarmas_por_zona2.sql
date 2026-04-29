-- View: public.vw_busca_alarmas_por_zona2
-- Vista para HomePage con radio fijo de 10km y filtro de 90 minutos
-- Fecha: 2025-12-16
-- Última modificación: 2025-12-21 - Agregado soporte para alarmas promocionales
--   - flag_visible_mapa ahora considera subscripciones publicitarias activas
--   - Agregados campos de subscripción publicitaria (radio, logo, contacto, domicilio)
--   - is_advertising flag para identificar alarmas promocionales
-- MODIFICADO: 2026-03-09 - Agregar categoria_alarma_id desde tipoalarma
--   - Usado en MAUI para mostrar/ocultar botón "Ver autoridades responsables"
--   - Solo SEGURIDAD (id=1) y POLITICA (id=2) muestran el botón

-- DROP VIEW IF EXISTS public.vw_busca_alarmas_por_zona2;

CREATE OR REPLACE VIEW public.vw_busca_alarmas_por_zona2
 AS
 SELECT p.user_id_thirdparty,
    p.persona_id,
    alper.user_id_thirdparty AS user_id_creador_alarma,
    p.login AS login_usuario_notificar,
    al.latitud AS latitud_alarma,
    al.longitud AS longitud_alarma,
    u.latitud AS latitud_entrada,
    u.longitud AS longitud_entrada,
    NULL::text AS tipo_subscr_activa_usuario,
    '2000-01-01 00:00:00'::timestamp without time zone AS fecha_activacion_subscr,
    '2000-01-01 00:00:00'::timestamp without time zone AS fecha_finalizacion_subscr,
    ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
    'MYSELF'::text AS relacion_social,
    al.alarma_id,
    al.fecha_alarma,
    ta.descripciontipoalarma,
    ta.tipoalarma_id,
    ta.categoria_alarma_id,
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
    case when al.estado_alarma is null then cast(true as boolean) else cast(false as boolean) end as EsAlarmaActiva,
    al.alarma_id_padre,
    al.calificacion_alarma,
    case when al.estado_alarma is null  then cast(true as boolean) else cast(false as boolean) end as estado_alarma,
    coalesce(dal.Flag_hubo_captura,cast(false as boolean)) as Flag_hubo_captura,
    case when  (select count(*) as cantidad_agentes_atendiendo from atencion_policiaca ap where ap.alarma_id=al.alarma_id) > 0 then cast (true as boolean) else cast (false as boolean) end as flag_alarma_siendo_atendida,
    (select count(*) as cantidad_agentes_atendiendo from atencion_policiaca ap where ap.alarma_id=al.alarma_id) as cantidad_agentes_atendiendo,
    (select count(*) as cantidad_interacciones from descripcionesalarmas dalt where dalt.alarma_id = al.alarma_id and dalt.veracidadalarma is null) as cantidad_interacciones,
    p.flag_es_policia,
    CAST(descr.descripcionalarma AS varchar(500)) AS Descripcionalarma,
    coalesce(alper.flag_red_confianza, cast(FALSE as boolean)) as flag_red_confianza,
    ra_usuario.radio_mts AS radio_alarmas_mts_actual,
    COALESCE(ta.radio_interes_metros, ra_usuario.radio_mts) AS radio_interes_metros,
    ta.minutos_vigencia,
    ta.tipo_cierre,
    COALESCE(multimedia.cantidad_videos, 0) AS cantidad_videos,
    COALESCE(multimedia.cantidad_fotos, 0) AS cantidad_fotos,
    CASE
        -- Para alarmas normales (no publicitarias)
        WHEN ta.is_advertising = FALSE AND al.estado_alarma IS NULL THEN true
        WHEN ta.is_advertising = FALSE AND al.estado_alarma IS NOT NULL AND al.fecha_alarma > NOW() - interval '90 minutes' THEN true
        -- Para alarmas publicitarias: requieren subscripción activa
        WHEN ta.is_advertising = TRUE AND subs_pub.subscripcion_id IS NOT NULL THEN true
        ELSE false
    END AS flag_visible_mapa,
    COALESCE(fotos_agg.fotos_json, '[]'::json) AS fotos_alarma,
    -- Campos específicos de alarmas promocionales
    COALESCE(ta.is_advertising, FALSE) AS is_advertising,
    subs_pub.radio_metros AS publicidad_radio_metros,
    subs_pub.logo_habilitado AS publicidad_logo_habilitado,
    subs_pub.url_logo AS publicidad_url_logo,
    subs_pub.contacto_habilitado AS publicidad_contacto_habilitado,
    subs_pub.domicilio_habilitado AS publicidad_domicilio_habilitado,
    subs_pub.fecha_finalizacion AS publicidad_fecha_finalizacion
   FROM ubicaciones u
     JOIN personas p ON p.persona_id = u.persona_id AND u."Tipo"::text = 'P'::text
     JOIN radio_alarmas ra_usuario ON ra_usuario.radio_alarmas_id = p.radio_alarmas_id
     JOIN radio_alarmas ra ON ra.radio_alarmas_id = 310
     JOIN alarmas al ON al.latitud >= (u.latitud - ra.radio_double) AND al.latitud <= (u.latitud + ra.radio_double) AND al.longitud >= (u.longitud - ra.radio_double) AND al.longitud <= (u.longitud + ra.radio_double)
     JOIN personas alper ON alper.persona_id = al.persona_id
     JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
     LEFT JOIN descripcionesalarmas dal ON dal.alarma_id = al.alarma_id AND dal.persona_id = p.persona_id AND dal.veracidadalarma IS NOT NULL
     LEFT JOIN ( SELECT al_1.alarma_id,
                CASE
                    WHEN count(*) = 0 THEN 1::bigint
                    ELSE count(*)
                END AS cantidad_verdadero
           FROM alarmas al_1
             LEFT JOIN descripcionesalarmas da ON al_1.alarma_id = da.alarma_id AND da.veracidadalarma = true
          WHERE al_1.estado_alarma IS NULL
          GROUP BY al_1.alarma_id) verdaderos ON al.alarma_id = verdaderos.alarma_id
     LEFT JOIN ( SELECT al_1.alarma_id,
                CASE
                    WHEN count(*) = 0 THEN 1::bigint
                    ELSE count(*)
                END AS cantidad_total
           FROM alarmas al_1
             LEFT JOIN descripcionesalarmas da ON al_1.alarma_id = da.alarma_id
          WHERE al_1.estado_alarma IS NULL
          GROUP BY al_1.alarma_id) total ON al.alarma_id = total.alarma_id
    LEFT JOIN (
        SELECT
            al_1.alarma_id,
            COALESCE(
                (
                    SELECT da.descripcionalarma
                    FROM descripcionesalarmas da
                    WHERE da.alarma_id = al_1.alarma_id
                    AND da.descripcionalarma IS NOT NULL
                    ORDER BY da.iddescripcion ASC
                    LIMIT 1
                ),
                (
                    SELECT da_padre.descripcionalarma
                    FROM descripcionesalarmas da_padre
                    WHERE da_padre.alarma_id = al_1.alarma_id_padre
                    AND da_padre.descripcionalarma IS NOT NULL
                    ORDER BY da_padre.iddescripcion ASC
                    LIMIT 1
                ),
                'Sin descripción por el momento'
            ) AS descripcionalarma
        FROM alarmas al_1
    ) descr ON al.alarma_id = descr.alarma_id
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
    LEFT JOIN (
        SELECT
            s.subscripcion_id,
            s.alarma_id,
            s.radio_metros,
            s.logo_habilitado,
            e.url_logo,
            s.contacto_habilitado,
            s.domicilio_habilitado,
            s.fecha_finalizacion
        FROM subscripciones s
        LEFT JOIN emprendimientos e ON s.id_emprendimiento = e.id_emprendimiento
          AND e.fecha_fin IS NULL
        WHERE s.alarma_id IS NOT NULL
          AND s.fecha_finalizacion >= NOW()
    ) subs_pub ON subs_pub.alarma_id = al.alarma_id
  WHERE
    (
        al.estado_alarma IS NULL
    )
    OR
    (
        al.estado_alarma IS NOT NULL AND
        al.fecha_alarma > NOW() - interval '90 minutes'
    );

