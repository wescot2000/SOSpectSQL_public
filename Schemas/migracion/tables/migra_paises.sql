-- Table: migracion.migra_paises
-- CREADO: 2026-04-25 - Migración de catálogo de países como dimensión geográfica para análisis

-- DROP TABLE IF EXISTS migracion.migra_paises;

CREATE TABLE IF NOT EXISTS migracion.migra_paises
(
    pais_id character(2) COLLATE pg_catalog."default",
    nombre_es character varying(100) COLLATE pg_catalog."default",
    name_en character varying(100) COLLATE pg_catalog."default",
    nom character varying(100) COLLATE pg_catalog."default",
    iso3 character varying(3) COLLATE pg_catalog."default",
    phone_code character varying(100) COLLATE pg_catalog."default",
    continente character varying(100) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;
