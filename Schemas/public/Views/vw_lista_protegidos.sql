-- View: public.vw_lista_protegidos

-- DROP VIEW public.vw_lista_protegidos;

CREATE OR REPLACE VIEW public.vw_lista_protegidos
 AS
 SELECT protector.user_id_thirdparty AS user_id_thirdparty_protector,
    protegido.user_id_thirdparty AS user_id_thirdparty_protegido,
    protector.login AS login_protector,
    protegido.login AS login_protegido,
    s.fecha_activacion,
    COALESCE(s.fecha_finalizacion, now() + '1000 days'::interval) AS fecha_finalizacion,
    s.poderes_consumidos
   FROM relacion_protegidos rp
     JOIN subscripciones s ON s.id_rel_protegido = rp.id_rel_protegido AND now() >= s.fecha_activacion AND now() <= COALESCE(s.fecha_finalizacion, now())
     JOIN permisos_pendientes_protegidos ppp ON ppp.persona_id_protector = rp.id_persona_protector AND ppp.persona_id_protegido = rp.id_persona_protegida AND ppp.flag_aprobado IS TRUE AND ppp.fecha_aprobado IS NOT NULL
     JOIN personas protector ON protector.persona_id = rp.id_persona_protector
     JOIN personas protegido ON protegido.persona_id = rp.id_persona_protegida
  WHERE now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now());

ALTER TABLE public.vw_lista_protegidos
    OWNER TO w4ll4c3;

