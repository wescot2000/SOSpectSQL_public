-- Table: migracion.migra_ubicaciones_testing

-- DROP TABLE IF EXISTS migracion.migra_ubicaciones_testing;

CREATE TABLE IF NOT EXISTS migracion.migra_ubicaciones_testing
(
    ubicacion_id bigint,
    persona_id bigint,
    latitud numeric(9,6),
    longitud numeric(9,6),
    fecha_ubicacion timestamp with time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_ubicaciones_testing
    OWNER to w4ll4c3;