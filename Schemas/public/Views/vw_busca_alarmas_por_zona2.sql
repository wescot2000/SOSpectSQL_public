-- View: public.vw_busca_alarmas_por_zona2

-- DROP VIEW public.vw_busca_alarmas_por_zona2;

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
  WHERE al.estado_alarma IS NULL;

ALTER TABLE public.vw_busca_alarmas_por_zona2
    OWNER TO w4ll4c3;

