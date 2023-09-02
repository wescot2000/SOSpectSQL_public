-- Table: migracion.migra_ubicaciones

-- DROP TABLE IF EXISTS migracion.migra_ubicaciones;

CREATE TABLE IF NOT EXISTS migracion.migra_ubicaciones
(
    ubicacion_id bigint,
    persona_id bigint,
    latitud numeric(9,6),
    longitud numeric(9,6),
    "Tipo" character varying(1) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_ubicaciones
    OWNER to w4ll4c3;