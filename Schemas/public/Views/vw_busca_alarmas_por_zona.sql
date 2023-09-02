-- View: public.vw_busca_alarmas_por_zona

-- DROP VIEW public.vw_busca_alarmas_por_zona;

CREATE OR REPLACE VIEW public.vw_busca_alarmas_por_zona
 AS
 SELECT p.user_id_thirdparty,
    p.persona_id,
    alper.user_id_thirdparty AS user_id_creador_alarma,
    p.login AS login_usuario_notificar,
    al.latitud AS latitud_alarma,
    al.longitud AS longitud_alarma,
    u.latitud AS latitud_entrada,
    u.longitud AS longitud_entrada,
    ts.descripcion_tipo AS tipo_subscr_activa_usuario,
    COALESCE(s.fecha_activacion, '2000-01-01 00:00:00'::timestamp without time zone::timestamp with time zone) AS fecha_activacion_subscr,
    COALESCE(s.fecha_finalizacion, '2000-01-01 00:00:00'::timestamp without time zone::timestamp with time zone) AS fecha_finalizacion_subscr,
    ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
    'MYSELF'::text AS relacion_social,
    al.alarma_id,
    al.fecha_alarma,
    ta.descripciontipoalarma,
    ta.tipoalarma_id,
    60::smallint AS tiemporefrescoubicacion,
        CASE
            WHEN p.user_id_thirdparty::text = alper.user_id_thirdparty::text THEN true
            WHEN al.alarma_id_padre IS NOT NULL THEN true
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
    al.alarma_id_padre,
    al.calificacion_alarma
   FROM ubicaciones u
     JOIN personas p ON p.persona_id = u.persona_id AND u."Tipo"::text = 'P'::text
     JOIN radio_alarmas ra ON p.radio_alarmas_id = ra.radio_alarmas_id
     LEFT JOIN subscripciones s ON s.persona_id = p.persona_id AND s.radio_alarmas_id IS NOT NULL AND now() >= s.fecha_activacion AND now() <= COALESCE(s.fecha_finalizacion, now())
     LEFT JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
     LEFT JOIN radio_alarmas ra_susc ON ra_susc.radio_alarmas_id = s.radio_alarmas_id
     JOIN alarmas al ON u.latitud >= (al.latitud -
        CASE
            WHEN ra_susc.radio_alarmas_id IS NOT NULL THEN ra_susc.radio_double
            ELSE ra.radio_double
        END) AND u.latitud <= (al.latitud +
        CASE
            WHEN ra_susc.radio_alarmas_id IS NOT NULL THEN ra_susc.radio_double
            ELSE ra.radio_double
        END) AND u.longitud >= (al.longitud -
        CASE
            WHEN ra_susc.radio_alarmas_id IS NOT NULL THEN ra_susc.radio_double
            ELSE ra.radio_double
        END) AND u.longitud <= (al.longitud +
        CASE
            WHEN ra_susc.radio_alarmas_id IS NOT NULL THEN ra_susc.radio_double
            ELSE ra.radio_double
        END)
     JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
     JOIN personas alper ON alper.persona_id = al.persona_id
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
  WHERE al.estado_alarma IS NULL AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text AND (al.tipoalarma_id <> ALL (ARRAY[4, 5, 6]))
UNION
 SELECT p.user_id_thirdparty,
    p.persona_id,
    alper.user_id_thirdparty AS user_id_creador_alarma,
    p.login AS login_usuario_notificar,
    al.latitud AS latitud_alarma,
    al.longitud AS longitud_alarma,
    u.latitud AS latitud_entrada,
    u.longitud AS longitud_entrada,
    NULL::character varying AS tipo_subscr_activa_usuario,
    '2000-01-01 00:00:00'::timestamp without time zone AS fecha_activacion_subscr,
    '2000-01-01 00:00:00'::timestamp without time zone AS fecha_finalizacion_subscr,
    ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
    'MYSELF'::text AS relacion_social,
    al.alarma_id,
    al.fecha_alarma,
    ta.descripciontipoalarma,
    ta.tipoalarma_id,
    60::smallint AS tiemporefrescoubicacion,
        CASE
            WHEN p.user_id_thirdparty::text = alper.user_id_thirdparty::text THEN true
            WHEN al.alarma_id_padre IS NOT NULL THEN true
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
    al.alarma_id_padre,
    al.calificacion_alarma
   FROM alarmas al
     JOIN ubicaciones u ON u.latitud >= (al.latitud - 0.090000) AND u.latitud <= (al.latitud + 0.090000) AND u.longitud >= (al.longitud - 0.090000) AND u.longitud <= (al.longitud + 0.090000) AND u."Tipo"::text = 'P'::text
     JOIN personas p ON p.persona_id = u.persona_id
     JOIN personas alper ON alper.persona_id = al.persona_id
     JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
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
  WHERE al.estado_alarma IS NULL AND (al.tipoalarma_id = ANY (ARRAY[4, 5])) AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
UNION
 SELECT p.user_id_thirdparty,
    p.persona_id,
    alper.user_id_thirdparty AS user_id_creador_alarma,
    p.login AS login_usuario_notificar,
    al.latitud AS latitud_alarma,
    al.longitud AS longitud_alarma,
    u.latitud AS latitud_entrada,
    u.longitud AS longitud_entrada,
    NULL::character varying AS tipo_subscr_activa_usuario,
    '2000-01-01 00:00:00'::timestamp without time zone AS fecha_activacion_subscr,
    '2000-01-01 00:00:00'::timestamp without time zone AS fecha_finalizacion_subscr,
    ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
    'MYSELF'::text AS relacion_social,
    al.alarma_id,
    al.fecha_alarma,
    ta.descripciontipoalarma,
    ta.tipoalarma_id,
    60::smallint AS tiemporefrescoubicacion,
        CASE
            WHEN p.user_id_thirdparty::text = alper.user_id_thirdparty::text THEN true
            WHEN al.alarma_id_padre IS NOT NULL THEN true
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
    al.alarma_id_padre,
    al.calificacion_alarma
   FROM alarmas al
     JOIN ubicaciones u ON u.latitud >= (al.latitud - 0.009000) AND u.latitud <= (al.latitud + 0.009000) AND u.longitud >= (al.longitud - 0.009000) AND u.longitud <= (al.longitud + 0.009000) AND u."Tipo"::text = 'P'::text
     JOIN personas p ON p.persona_id = u.persona_id
     JOIN personas alper ON alper.persona_id = al.persona_id
     JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
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
  WHERE al.estado_alarma IS NULL AND al.tipoalarma_id = 6 AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
UNION
 SELECT p.user_id_thirdparty,
    p.persona_id,
    alper.user_id_thirdparty AS user_id_creador_alarma,
    p.login AS login_usuario_notificar,
    al.latitud AS latitud_alarma,
    al.longitud AS longitud_alarma,
    u.latitud AS latitud_entrada,
    u.longitud AS longitud_entrada,
    NULL::character varying AS tipo_subscr_activa_usuario,
    '2000-01-01 00:00:00'::timestamp without time zone AS fecha_activacion_subscr,
    '2000-01-01 00:00:00'::timestamp without time zone AS fecha_finalizacion_subscr,
    ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
    'MYSELF'::text AS relacion_social,
    al.alarma_id,
    al.fecha_alarma,
    ta.descripciontipoalarma,
    ta.tipoalarma_id,
    60::smallint AS tiemporefrescoubicacion,
        CASE
            WHEN p.user_id_thirdparty::text = alper.user_id_thirdparty::text THEN true
            WHEN al.alarma_id_padre IS NOT NULL THEN true
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
    al.alarma_id_padre,
    al.calificacion_alarma
   FROM alarmas al
     JOIN ubicaciones u ON u.latitud >= (al.latitud - 9.000000) AND u.latitud <= (al.latitud + 9.000000) AND u.longitud >= (al.longitud - 9.000000) AND u.longitud <= (al.longitud + 9.000000) AND u."Tipo"::text = 'P'::text
     JOIN personas p ON p.persona_id = u.persona_id
     JOIN personas alper ON alper.persona_id = al.persona_id
     JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
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
  WHERE al.estado_alarma IS NULL AND p.user_id_thirdparty::text = alper.user_id_thirdparty::text
UNION
 SELECT p.user_id_thirdparty,
    p.persona_id,
    alper.user_id_thirdparty AS user_id_creador_alarma,
    p.login AS login_usuario_notificar,
    al.latitud AS latitud_alarma,
    al.longitud AS longitud_alarma,
    u.latitud AS latitud_entrada,
    u.longitud AS longitud_entrada,
    NULL::character varying AS tipo_subscr_activa_usuario,
    '2000-01-01 00:00:00'::timestamp without time zone AS fecha_activacion_subscr,
    '2000-01-01 00:00:00'::timestamp without time zone AS fecha_finalizacion_subscr,
    ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
    tr.descripciontiporel AS relacion_social,
    al.alarma_id,
    al.fecha_alarma,
    ta.descripciontipoalarma,
    ta.tipoalarma_id,
    60::smallint AS tiemporefrescoubicacion,
        CASE
            WHEN p.user_id_thirdparty::text = alper.user_id_thirdparty::text THEN true
            WHEN al.alarma_id_padre IS NOT NULL THEN true
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
    al.alarma_id_padre,
    al.calificacion_alarma
   FROM alarmas al
     JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now()) AND (rp.fecha_suspension IS NULL AND rp.fecha_reactivacion IS NULL OR rp.fecha_suspension IS NULL AND rp.fecha_reactivacion <= now() OR rp.fecha_reactivacion IS NULL AND rp.fecha_suspension >= now() OR now() < rp.fecha_suspension OR now() > rp.fecha_reactivacion)
     JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
     JOIN tiporelacion tr ON tr.tiporelacion_id = rp.tiporelacion_id
     JOIN personas alper ON alper.persona_id = rp.id_persona_protegida
     JOIN subscripciones s ON rp.id_rel_protegido = s.id_rel_protegido AND al.fecha_alarma >= s.fecha_activacion AND al.fecha_alarma <= COALESCE(s.fecha_finalizacion, now())
     JOIN personas p ON p.persona_id = s.persona_id
     JOIN radio_alarmas ra ON p.radio_alarmas_id = ra.radio_alarmas_id
     LEFT JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
     JOIN ubicaciones u ON u.persona_id = p.persona_id AND u."Tipo"::text = 'P'::text
     JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
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
     LEFT JOIN descripcionesalarmas dal ON dal.alarma_id = al.alarma_id AND dal.persona_id = p.persona_id AND dal.veracidadalarma IS NOT NULL
  WHERE al.estado_alarma IS NULL AND (al.tipoalarma_id <> ALL (ARRAY[4, 5, 6])) AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
UNION
 SELECT p.user_id_thirdparty,
    p.persona_id,
    alper.user_id_thirdparty AS user_id_creador_alarma,
    p.login AS login_usuario_notificar,
    al.latitud AS latitud_alarma,
    al.longitud AS longitud_alarma,
    u.latitud AS latitud_entrada,
    u.longitud AS longitud_entrada,
    NULL::character varying AS tipo_subscr_activa_usuario,
    '2000-01-01 00:00:00'::timestamp without time zone AS fecha_activacion_subscr,
    '2000-01-01 00:00:00'::timestamp without time zone AS fecha_finalizacion_subscr,
    ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
    'SURVEY_ZONE'::text AS relacion_social,
    al.alarma_id,
    al.fecha_alarma,
    ta.descripciontipoalarma,
    ta.tipoalarma_id,
    60::smallint AS tiemporefrescoubicacion,
        CASE
            WHEN p.user_id_thirdparty::text = alper.user_id_thirdparty::text THEN true
            WHEN al.alarma_id_padre IS NOT NULL THEN true
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
    al.alarma_id_padre,
    al.calificacion_alarma
   FROM alarmas al
     JOIN ubicaciones u ON u.latitud >= (al.latitud - 0.001800) AND u.latitud <= (al.latitud + 0.001800) AND u.longitud >= (al.longitud - 0.001800) AND u.longitud <= (al.longitud + 0.001800) AND u."Tipo"::text = 'S'::text
     JOIN personas p ON p.persona_id = u.persona_id
     JOIN subscripciones s ON u.ubicacion_id = s.ubicacion_id AND u."Tipo"::text = 'S'::text AND now() >= s.fecha_activacion AND now() <= COALESCE(s.fecha_finalizacion, now())
     JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
     JOIN personas alper ON alper.persona_id = al.persona_id
     JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
     JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
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
     LEFT JOIN descripcionesalarmas dal ON dal.alarma_id = al.alarma_id AND dal.persona_id = p.persona_id AND dal.veracidadalarma IS NOT NULL
  WHERE al.estado_alarma IS NULL AND (al.tipoalarma_id <> ALL (ARRAY[4, 5, 6])) AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text;

ALTER TABLE public.vw_busca_alarmas_por_zona
    OWNER TO w4ll4c3;

