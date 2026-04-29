-- Table: migracion.migra_alarmas_reenvios
-- CREADO: 2026-04-25 - Migración de reenvíos de alarmas cerradas para análisis de engagement

-- DROP TABLE IF EXISTS migracion.migra_alarmas_reenvios;

CREATE TABLE IF NOT EXISTS migracion.migra_alarmas_reenvios
(
    reenvio_id bigint,
    alarma_id bigint,
    persona_id bigint,
    fecha_reenvio timestamp with time zone
)

TABLESPACE pg_default;
