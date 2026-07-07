-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: wiped.sesiones_app
-- CREADO: 2026-07-06 - Backup de sesiones de analitica antes de eliminar datos del usuario.
-- Necesaria porque public.sesiones_app tiene FK RESTRICT a personas (fk_sesiones_app_persona),
-- lo que bloqueaba el DELETE FROM public.personas en wiped.eliminarusuario().

-- DROP TABLE IF EXISTS wiped.sesiones_app;

CREATE TABLE IF NOT EXISTS wiped.sesiones_app
(
    sesion_id bigint,
    persona_id bigint,
    fecha_inicio timestamp with time zone,
    fecha_fin timestamp with time zone,
    duracion_segundos integer,
    plataforma character varying(20) COLLATE pg_catalog."default",
    fuente_apertura character varying(30) COLLATE pg_catalog."default",
    latitud numeric(9,6),
    longitud numeric(9,6)
)

TABLESPACE pg_default;
