-- Table: migracion.migra_pol_territorios
-- CREADO: 2026-04-25 - Migración de catálogo de territorios políticos como dimensión para análisis

-- DROP TABLE IF EXISTS migracion.migra_pol_territorios;

CREATE TABLE IF NOT EXISTS migracion.migra_pol_territorios
(
    territorio_id integer,
    nivel character varying(20) COLLATE pg_catalog."default",
    nombre_nivel_local character varying(50) COLLATE pg_catalog."default",
    nombre character varying(150) COLLATE pg_catalog."default",
    nombre_oficial character varying(150) COLLATE pg_catalog."default",
    codigo_dane character varying(20) COLLATE pg_catalog."default",
    parent_id integer,
    parent_pais_id character(2) COLLATE pg_catalog."default",
    path text,
    activo boolean,
    created_at timestamp with time zone
)

TABLESPACE pg_default;
