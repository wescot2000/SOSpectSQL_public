-- View: public.vw_consulta_parametros_usuario

-- DROP VIEW public.vw_consulta_parametros_usuario;

CREATE OR REPLACE VIEW public.vw_consulta_parametros_usuario
 AS
 SELECT p.user_id_thirdparty,
    p.tiempo_refresco_mapa,
    p.marca_bloqueo,
    p.saldo_poderes,
    ra.radio_mts,
    COALESCE(msgs.mensajesparausuario, 0::bigint) AS mensajesparausuario,
        CASE
            WHEN p.marca_bloqueo = 6 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '60 days'::interval day) THEN true
            WHEN p.marca_bloqueo = 9 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '180 days'::interval day) THEN true
            WHEN p.marca_bloqueo = 10 THEN true
            ELSE false
        END AS flag_bloqueo_usuario,
        CASE
            WHEN ac.persona_id IS NULL AND cs.contrato_id IS NULL THEN true
            ELSE false
        END AS flag_usuario_debe_firmar_cto,
    COALESCE(dis.idioma, 'en'::character varying) AS idioma_destino,
    dis.registrationid,
    u.latitud,
    u.longitud,
        CASE
            WHEN p.marca_bloqueo = 6 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '60 days'::interval day) THEN p.fecha_ultima_marca_bloqueo + '60 days'::interval day
            WHEN p.marca_bloqueo = 9 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '180 days'::interval day) THEN p.fecha_ultima_marca_bloqueo + '180 days'::interval day
            WHEN p.marca_bloqueo = 10 THEN p.fecha_ultima_marca_bloqueo + '10 years'::interval year
            ELSE now()
        END AS fechafin_bloqueo_usuario,
    ( SELECT min(obtener_radio_alarmas.radio_mts) - 100
           FROM obtener_radio_alarmas(p.user_id_thirdparty) obtener_radio_alarmas(radio_alarmas_id, radio_mts)) AS radio_alarmas_mts_actual,
    p.credibilidad_persona
   FROM personas p
     JOIN ubicaciones u ON u.persona_id = p.persona_id AND u."Tipo"::text = 'P'::text
     JOIN radio_alarmas ra ON ra.radio_alarmas_id = p.radio_alarmas_id
     LEFT JOIN alarmas al ON al.persona_id = p.persona_id AND al.estado_alarma IS NOT NULL AND al.calificacion_alarma IS NOT NULL AND al.calificacion_alarma < 6::numeric AND al.fecha_alarma > (now() - '1 day'::interval day)
     LEFT JOIN aceptacion_condiciones ac ON ac.persona_id = p.persona_id
     LEFT JOIN condiciones_servicio cs ON cs.contrato_id = ac.contrato_id AND cs.fecha_fin_version IS NULL
     LEFT JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
     LEFT JOIN ( SELECT count(*) AS mensajesparausuario,
            mensajes_a_usuarios.persona_id
           FROM mensajes_a_usuarios
          WHERE mensajes_a_usuarios.estado IS TRUE AND mensajes_a_usuarios.fecha_mensaje > (now() - '15 days'::interval)
          GROUP BY mensajes_a_usuarios.persona_id) msgs ON msgs.persona_id = p.persona_id
  GROUP BY p.user_id_thirdparty, p.tiempo_refresco_mapa, p.marca_bloqueo, p.saldo_poderes, ra.radio_mts, msgs.mensajesparausuario, (
        CASE
            WHEN p.marca_bloqueo = 6 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '60 days'::interval day) THEN true
            WHEN p.marca_bloqueo = 9 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '180 days'::interval day) THEN true
            WHEN p.marca_bloqueo = 10 THEN true
            ELSE false
        END), (
        CASE
            WHEN ac.persona_id IS NULL AND cs.contrato_id IS NULL THEN true
            ELSE false
        END), ac.persona_id, cs.contrato_id, (COALESCE(dis.idioma, 'en'::character varying)), dis.registrationid, u.latitud, u.longitud, (
        CASE
            WHEN p.marca_bloqueo = 6 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '60 days'::interval day) THEN p.fecha_ultima_marca_bloqueo + '60 days'::interval day
            WHEN p.marca_bloqueo = 9 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '180 days'::interval day) THEN p.fecha_ultima_marca_bloqueo + '180 days'::interval day
            WHEN p.marca_bloqueo = 10 THEN p.fecha_ultima_marca_bloqueo + '10 years'::interval year
            ELSE now()
        END), (( SELECT min(obtener_radio_alarmas.radio_mts) - 100
           FROM obtener_radio_alarmas(p.user_id_thirdparty) obtener_radio_alarmas(radio_alarmas_id, radio_mts))), p.credibilidad_persona;

ALTER TABLE public.vw_consulta_parametros_usuario
    OWNER TO w4ll4c3;

