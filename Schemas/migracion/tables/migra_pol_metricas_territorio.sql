-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_pol_metricas_territorio
-- CREADO: 2026-04-25 - Migración de métricas territoriales para análisis de series de tiempo por territorio

-- DROP TABLE IF EXISTS migracion.migra_pol_metricas_territorio;

CREATE TABLE IF NOT EXISTS migracion.migra_pol_metricas_territorio
(
    metrica_id integer,
    territorio_id integer,
    pais_id character(2) COLLATE pg_catalog."default",
    periodo character varying(5) COLLATE pg_catalog."default",
    cnt_alarmas integer,
    cnt_alarmas_politico integer,
    fecha_calculo timestamp with time zone
)

TABLESPACE pg_default;


