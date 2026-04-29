-- Table: migracion.migra_alarmas_territorio
-- CREADO: 2026-04-25 - Migración de datos geográficos de alarmas cerradas para análisis territorial

-- DROP TABLE IF EXISTS migracion.migra_alarmas_territorio;

CREATE TABLE IF NOT EXISTS migracion.migra_alarmas_territorio
(
    alarma_id bigint,
    barrio character varying(150) COLLATE pg_catalog."default",
    ciudad character varying(150) COLLATE pg_catalog."default",
    pais character varying(100) COLLATE pg_catalog."default",
    created_at timestamp without time zone,
    barrio_normalizado character varying(150) COLLATE pg_catalog."default",
    ciudad_normalizada character varying(150) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;
