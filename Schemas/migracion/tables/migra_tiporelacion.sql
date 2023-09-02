-- Table: migracion.migra_tiporelacion

-- DROP TABLE IF EXISTS migracion.migra_tiporelacion;

CREATE TABLE IF NOT EXISTS migracion.migra_tiporelacion
(
    tiporelacion_id integer,
    descripciontiporel character varying(150) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_tiporelacion
    OWNER to w4ll4c3;