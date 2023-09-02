-- Table: migracion.migra_valorsubscripciones

-- DROP TABLE IF EXISTS migracion.migra_valorsubscripciones;

CREATE TABLE IF NOT EXISTS migracion.migra_valorsubscripciones
(
    valorsubscripcion_id integer,
    tipo_subscr_id integer,
    cantidad_subscripcion integer,
    cantidad_poderes integer,
    tiempo_subscripcion_horas integer
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_valorsubscripciones
    OWNER to w4ll4c3;