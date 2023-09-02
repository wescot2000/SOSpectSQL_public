-- Table: migracion.migra_tipoalarma

-- DROP TABLE IF EXISTS migracion.migra_tipoalarma;

CREATE TABLE IF NOT EXISTS migracion.migra_tipoalarma
(
    tipoalarma_id integer,
    descripciontipoalarma character varying(50) COLLATE pg_catalog."default",
    icono character varying(50) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_tipoalarma
    OWNER to w4ll4c3;