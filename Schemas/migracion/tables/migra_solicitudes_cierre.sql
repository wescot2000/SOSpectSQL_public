-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_solicitudes_cierre
-- CREADO: 2026-04-25 - Migración de solicitudes de cierre resueltas para análisis de gobernanza comunitaria

-- DROP TABLE IF EXISTS migracion.migra_solicitudes_cierre;

CREATE TABLE IF NOT EXISTS migracion.migra_solicitudes_cierre
(
    solicitud_id bigint,
    alarma_id bigint,
    persona_id bigint,
    descripcion character varying(500) COLLATE pg_catalog."default",
    fecha_solicitud timestamp with time zone,
    fecha_limite_votacion timestamp with time zone,
    estado character varying(20) COLLATE pg_catalog."default",
    votos_si integer,
    votos_no integer,
    iddescripcion_propuesta bigint
)

TABLESPACE pg_default;


