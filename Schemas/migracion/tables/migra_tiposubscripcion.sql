-- Table: migracion.migra_tiposubscripcion

-- DROP TABLE IF EXISTS migracion.migra_tiposubscripcion;

CREATE TABLE IF NOT EXISTS migracion.migra_tiposubscripcion
(
    tipo_subscr_id integer,
    descripcion_tipo character varying(100) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;
