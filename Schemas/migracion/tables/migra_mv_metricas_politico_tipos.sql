-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_mv_metricas_politico_tipos
-- CREADO: 2026-04-25 - Migración de snapshot de métricas por tipo de alarma por político

-- DROP TABLE IF EXISTS migracion.migra_mv_metricas_politico_tipos;

CREATE TABLE IF NOT EXISTS migracion.migra_mv_metricas_politico_tipos
(
    id bigint,
    politico_id integer,
    tipoalarma_id bigint,
    cnt integer,
    pct numeric(5,1)
)

TABLESPACE pg_default;


