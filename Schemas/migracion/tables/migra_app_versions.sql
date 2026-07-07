-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_app_versions

-- DROP TABLE IF EXISTS migracion.migra_app_versions;

CREATE TABLE IF NOT EXISTS migracion.migra_app_versions
(
    id integer,
    version_number character varying(10) COLLATE pg_catalog."default",
    is_supported boolean,
    date_added timestamp without time zone,
    plataforma character varying(20) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;


