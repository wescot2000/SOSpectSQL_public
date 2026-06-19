-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_personas_seguidores
-- CREADO: 2026-04-25 - Migración de relaciones de seguimiento para análisis de influencia social

-- DROP TABLE IF EXISTS migracion.migra_personas_seguidores;

CREATE TABLE IF NOT EXISTS migracion.migra_personas_seguidores
(
    seguimiento_id bigint,
    seguidor_persona_id bigint,
    seguido_persona_id bigint,
    fecha_seguimiento timestamp with time zone
)

TABLESPACE pg_default;


