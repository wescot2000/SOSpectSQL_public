-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_pol_vigencias
-- CREADO: 2026-04-25 - Migración de vigencias de cargos políticos para contexto histórico de análisis

-- DROP TABLE IF EXISTS migracion.migra_pol_vigencias;

CREATE TABLE IF NOT EXISTS migracion.migra_pol_vigencias
(
    vigencia_id integer,
    politico_id integer,
    cargo_id smallint,
    territorio_id integer,
    pais_id character(2) COLLATE pg_catalog."default",
    fecha_inicio date,
    fecha_fin date,
    activo boolean,
    created_at timestamp with time zone
)

TABLESPACE pg_default;


