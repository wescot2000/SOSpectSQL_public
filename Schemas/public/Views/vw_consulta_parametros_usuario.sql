-- View: public.vw_consulta_parametros_usuario
-- MODIFICADO: 2026-03-02 - Revertir JOIN paises_convenios a pais_id.
--   iso_alpha_2 fue agregada a la tabla pero nunca se pobló (0 registros), causando que
--   flag_convenio siempre retorne NULL y explote con GetBoolean(). pais_id ya contiene
--   el código ISO alpha-2 de 2 chars (CO, US, MX...) y sí hace match correctamente.

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
            WHEN ac.persona_id IS NULL THEN true
            ELSE false
        END AS flag_usuario_debe_firmar_cto,
    COALESCE(dis.idioma, 'en'::character varying) AS idioma_destino,
    dis.registrationid,
    COALESCE(u.latitud, cast('4.656887' as numeric(9,6))) AS latitud,
    COALESCE(u.longitud, cast('-74.093267' as numeric(9,6))) AS longitud,
        CASE
            WHEN p.marca_bloqueo = 6 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '60 days'::interval day) THEN p.fecha_ultima_marca_bloqueo + '60 days'::interval day
            WHEN p.marca_bloqueo = 9 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '180 days'::interval day) THEN p.fecha_ultima_marca_bloqueo + '180 days'::interval day
            WHEN p.marca_bloqueo = 10 THEN p.fecha_ultima_marca_bloqueo + '10 years'::interval year
            ELSE now()
        END AS fechafin_bloqueo_usuario,
    ( SELECT min(obtener_radio_alarmas.radio_mts) - 100
           FROM obtener_radio_alarmas(p.user_id_thirdparty) obtener_radio_alarmas(radio_alarmas_id, radio_mts)) AS radio_alarmas_mts_actual,
    p.credibilidad_persona,
    coalesce(p.flag_red_confianza, cast(FALSE as boolean)) as flag_red_confianza,
    pc.flag AS flag_convenio,
    ccp.costo_base_promocion,
    ccp.costo_logo,
    ccp.costo_contacto,
    ccp.costo_domicilio,
    ccp.costo_por_500m_extra,
    ccp.costo_por_dia_extra,
    ccp.costo_por_media_extra,
    ccp.costo_por_50_usuarios_push,
    p.limite_alarmas_feed
   FROM personas p
     LEFT JOIN ubicaciones u ON u.persona_id = p.persona_id AND u."Tipo"::text = 'P'::text
     JOIN radio_alarmas ra ON ra.radio_alarmas_id = p.radio_alarmas_id
     LEFT JOIN alarmas al ON al.persona_id = p.persona_id AND al.estado_alarma IS NOT NULL AND al.calificacion_alarma IS NOT NULL AND al.calificacion_alarma < 6::numeric AND al.fecha_alarma > (now() - '1 day'::interval day)
     LEFT JOIN condiciones_servicio cs_vigente ON cs_vigente.fecha_fin_version IS NULL
     LEFT JOIN aceptacion_condiciones ac ON ac.persona_id = p.persona_id AND ac.contrato_id = cs_vigente.contrato_id
     LEFT JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
     LEFT JOIN paises_convenios pc ON pc.pais_id = COALESCE(u.pais_id, dis.pais_id) AND pc.fecha_fin IS NULL
     LEFT JOIN ( SELECT count(*) AS mensajesparausuario,
            mensajes_a_usuarios.persona_id
           FROM mensajes_a_usuarios
          WHERE mensajes_a_usuarios.estado IS TRUE AND mensajes_a_usuarios.fecha_mensaje > (now() - '15 days'::interval)
          GROUP BY mensajes_a_usuarios.persona_id) msgs ON msgs.persona_id = p.persona_id
     CROSS JOIN configuracion_costos_promocionales ccp
  GROUP BY p.user_id_thirdparty, p.tiempo_refresco_mapa, p.marca_bloqueo, p.saldo_poderes, ra.radio_mts, msgs.mensajesparausuario, (
        CASE
            WHEN p.marca_bloqueo = 6 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '60 days'::interval day) THEN true
            WHEN p.marca_bloqueo = 9 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '180 days'::interval day) THEN true
            WHEN p.marca_bloqueo = 10 THEN true
            ELSE false
        END), (
        CASE
            WHEN ac.persona_id IS NULL THEN true
            ELSE false
        END), ac.persona_id, (COALESCE(dis.idioma, 'en'::character varying)), dis.registrationid, u.latitud, u.longitud, (
        CASE
            WHEN p.marca_bloqueo = 6 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '60 days'::interval day) THEN p.fecha_ultima_marca_bloqueo + '60 days'::interval day
            WHEN p.marca_bloqueo = 9 AND now() >= p.fecha_ultima_marca_bloqueo AND now() <= (p.fecha_ultima_marca_bloqueo + '180 days'::interval day) THEN p.fecha_ultima_marca_bloqueo + '180 days'::interval day
            WHEN p.marca_bloqueo = 10 THEN p.fecha_ultima_marca_bloqueo + '10 years'::interval year
            ELSE now()
        END), (( SELECT min(obtener_radio_alarmas.radio_mts) - 100
           FROM obtener_radio_alarmas(p.user_id_thirdparty) obtener_radio_alarmas(radio_alarmas_id, radio_mts))), p.credibilidad_persona,coalesce(p.flag_red_confianza, cast(FALSE as boolean)),pc.flag,
    ccp.costo_base_promocion, ccp.costo_logo, ccp.costo_contacto, ccp.costo_domicilio,
    ccp.costo_por_500m_extra, ccp.costo_por_dia_extra, ccp.costo_por_media_extra, ccp.costo_por_50_usuarios_push, p.limite_alarmas_feed;


