-- Table: migracion.migra_alarmas_likes
-- CREADO: 2026-04-25 - Migración de likes de alarmas cerradas para análisis de engagement

-- DROP TABLE IF EXISTS migracion.migra_alarmas_likes;

CREATE TABLE IF NOT EXISTS migracion.migra_alarmas_likes
(
    like_id bigint,
    alarma_id bigint,
    persona_id bigint,
    fecha_like timestamp with time zone
)

TABLESPACE pg_default;
