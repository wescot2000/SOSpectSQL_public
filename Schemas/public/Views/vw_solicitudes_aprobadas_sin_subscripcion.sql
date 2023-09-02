-- View: public.vw_solicitudes_aprobadas_sin_subscripcion

-- DROP VIEW public.vw_solicitudes_aprobadas_sin_subscripcion;

CREATE OR REPLACE VIEW public.vw_solicitudes_aprobadas_sin_subscripcion
 AS
 SELECT pprot.user_id_thirdparty AS user_id_thirdparty_protector,
    p.user_id_thirdparty AS user_id_thirdparty_protegido,
    p.login,
    aprobacion.fecha_aprobado,
    aprobacion.tiporelacion_id
   FROM permisos_pendientes_protegidos aprobacion
     JOIN personas p ON p.persona_id = aprobacion.persona_id_protegido
     JOIN personas pprot ON pprot.persona_id = aprobacion.persona_id_protector
     LEFT JOIN relacion_protegidos rp ON rp.id_persona_protector = aprobacion.persona_id_protector AND rp.id_persona_protegida = aprobacion.persona_id_protegido AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now())
  WHERE aprobacion.flag_aprobado IS TRUE AND aprobacion.fecha_aprobado IS NOT NULL AND rp.id_rel_protegido IS NULL;

ALTER TABLE public.vw_solicitudes_aprobadas_sin_subscripcion
    OWNER TO w4ll4c3;

