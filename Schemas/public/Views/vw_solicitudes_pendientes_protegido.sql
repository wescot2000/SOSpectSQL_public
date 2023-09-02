-- View: public.vw_solicitudes_pendientes_protegido

-- DROP VIEW public.vw_solicitudes_pendientes_protegido;

CREATE OR REPLACE VIEW public.vw_solicitudes_pendientes_protegido
 AS
 SELECT p.user_id_thirdparty,
    pprot.user_id_thirdparty AS user_id_thirdparty_protector,
    pprot.login,
    aprobacion.fecha_solicitud
   FROM permisos_pendientes_protegidos aprobacion
     JOIN personas p ON p.persona_id = aprobacion.persona_id_protegido
     JOIN personas pprot ON pprot.persona_id = aprobacion.persona_id_protector
  WHERE aprobacion.flag_aprobado IS NOT TRUE AND aprobacion.fecha_aprobado IS NULL;

ALTER TABLE public.vw_solicitudes_pendientes_protegido
    OWNER TO w4ll4c3;

