-- Table: migracion.migra_pol_politicos
-- CREADO: 2026-04-25 - Migración de catálogo de políticos como dimensión para análisis de desempeño

-- DROP TABLE IF EXISTS migracion.migra_pol_politicos;

CREATE TABLE IF NOT EXISTS migracion.migra_pol_politicos
(
    politico_id integer,
    nombre_completo character varying(200) COLLATE pg_catalog."default",
    foto_url character varying(500) COLLATE pg_catalog."default",
    partido character varying(150) COLLATE pg_catalog."default",
    email character varying(200) COLLATE pg_catalog."default",
    telefono character varying(50) COLLATE pg_catalog."default",
    sitio_web character varying(500) COLLATE pg_catalog."default",
    twitter character varying(150) COLLATE pg_catalog."default",
    activo boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
)

TABLESPACE pg_default;
