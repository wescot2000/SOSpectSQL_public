-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_pol_homologacion_google
-- CREADO: 2026-04-25 - Migración de mapeo de nombres Google a territorios para enriquecer análisis geográfico

-- DROP TABLE IF EXISTS migracion.migra_pol_homologacion_google;

CREATE TABLE IF NOT EXISTS migracion.migra_pol_homologacion_google
(
    homologacion_id integer,
    nombre_google character varying(200) COLLATE pg_catalog."default",
    nombre_google_normalizado character varying(200) COLLATE pg_catalog."default",
    nivel_google character varying(20) COLLATE pg_catalog."default",
    territorio_id integer,
    pais_id character(2) COLLATE pg_catalog."default",
    activo boolean,
    created_at timestamp with time zone
)

TABLESPACE pg_default;


