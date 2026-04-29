-- Table: wiped.ubicaciones_testing

-- DROP TABLE IF EXISTS wiped.ubicaciones_testing;

CREATE TABLE IF NOT EXISTS wiped.ubicaciones_testing
(
    ubicacion_id bigint,
    persona_id bigint,
    latitud numeric(9,6),
    longitud numeric(9,6),
    fecha_ubicacion timestamp with time zone,
    pais_id character varying(3) COLLATE pg_catalog."default",
)

TABLESPACE pg_default;
