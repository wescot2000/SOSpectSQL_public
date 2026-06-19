-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

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
     LEFT JOIN relacion_protegidos rp ON rp.id_persona_protector = aprobacion.persona_id_protector AND rp.id_persona_protegida = aprobacion.persona_id_protegido AND rp.fecha_finalizacion IS NULL
  WHERE aprobacion.flag_aprobado IS TRUE AND aprobacion.fecha_aprobado IS NOT NULL AND rp.id_rel_protegido IS NULL;




