-- Table: migracion.migra_atencion_policiaca

-- DROP TABLE IF EXISTS migracion.migra_atencion_policiaca;

CREATE TABLE IF NOT EXISTS migracion.migra_atencion_policiaca
(
    atencion_policiaca_id bigint,
    alarma_id bigint,
    persona_id bigint,
    fecha_autoasignacion timestamp with time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_atencion_policiaca
    OWNER to w4ll4c3;