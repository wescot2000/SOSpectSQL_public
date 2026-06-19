-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

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




