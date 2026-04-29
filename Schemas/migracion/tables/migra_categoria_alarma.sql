-- Table: migracion.migra_categoria_alarma
-- CREADO: 2026-04-25 - Migración de catálogo de categorías de alarma como dimensión analítica

-- DROP TABLE IF EXISTS migracion.migra_categoria_alarma;

CREATE TABLE IF NOT EXISTS migracion.migra_categoria_alarma
(
    categoria_alarma_id integer,
    nombre character varying(50) COLLATE pg_catalog."default",
    descripcion character varying(500) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;
