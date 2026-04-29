-- Table: wiped.atencion_policiaca

-- DROP TABLE IF EXISTS wiped.atencion_policiaca;

CREATE TABLE IF NOT EXISTS wiped.atencion_policiaca
(
    atencion_policiaca_id bigint,
    alarma_id bigint,
    persona_id bigint,
    fecha_autoasignacion timestamp with time zone
)

TABLESPACE pg_default;
