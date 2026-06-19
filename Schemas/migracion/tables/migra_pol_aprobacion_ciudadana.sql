-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_pol_aprobacion_ciudadana
-- CREADO: 2026-04-25 - Migración de calificaciones ciudadanas a políticos para análisis de series de tiempo de aprobación

-- DROP TABLE IF EXISTS migracion.migra_pol_aprobacion_ciudadana;

CREATE TABLE IF NOT EXISTS migracion.migra_pol_aprobacion_ciudadana
(
    aprobacion_id bigint,
    politico_id integer,
    persona_id bigint,
    calificacion smallint,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
)

TABLESPACE pg_default;


