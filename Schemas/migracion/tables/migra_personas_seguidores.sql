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
