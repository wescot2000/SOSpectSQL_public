-- Table: migracion.migra_condiciones_servicio

-- DROP TABLE IF EXISTS migracion.migra_condiciones_servicio;

CREATE TABLE IF NOT EXISTS migracion.migra_condiciones_servicio
(
    contrato_id integer,
    version_contrato character varying(50) COLLATE pg_catalog."default",
    fecha_inicio_version timestamp with time zone,
    fecha_fin_version timestamp with time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_condiciones_servicio
    OWNER to w4ll4c3;