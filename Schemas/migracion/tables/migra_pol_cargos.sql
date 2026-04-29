-- Table: migracion.migra_pol_cargos
-- CREADO: 2026-04-25 - Migración de catálogo de cargos políticos como dimensión para análisis

-- DROP TABLE IF EXISTS migracion.migra_pol_cargos;

CREATE TABLE IF NOT EXISTS migracion.migra_pol_cargos
(
    cargo_id smallint,
    nombre_cargo character varying(100) COLLATE pg_catalog."default",
    nivel_territorial character varying(20) COLLATE pg_catalog."default",
    orden_jerarquico smallint,
    activo boolean
)

TABLESPACE pg_default;
