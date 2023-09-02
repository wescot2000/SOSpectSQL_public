-- Table: migracion.migra_radio_alarmas

-- DROP TABLE IF EXISTS migracion.migra_radio_alarmas;

CREATE TABLE IF NOT EXISTS migracion.migra_radio_alarmas
(
    radio_alarmas_id integer,
    radio_mts integer,
    radio_double numeric(8,6),
    poderes_consumidos integer
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_radio_alarmas
    OWNER to w4ll4c3;