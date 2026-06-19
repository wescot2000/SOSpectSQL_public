-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_votos_cierre
-- CREADO: 2026-04-25 - Migración de votos de cierre para análisis de participación comunitaria

-- DROP TABLE IF EXISTS migracion.migra_votos_cierre;

CREATE TABLE IF NOT EXISTS migracion.migra_votos_cierre
(
    voto_id bigint,
    solicitud_id bigint,
    persona_id bigint,
    voto boolean,
    fecha_voto timestamp with time zone
)

TABLESPACE pg_default;


