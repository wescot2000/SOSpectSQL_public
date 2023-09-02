-- Table: migracion.migra_aceptacion_condiciones

-- DROP TABLE IF EXISTS migracion.migra_aceptacion_condiciones;

CREATE TABLE IF NOT EXISTS migracion.migra_aceptacion_condiciones
(
    aceptacion_id bigint,
    persona_id bigint,
    contrato_id integer,
    numeral_contrato integer,
    fecha_aceptacion timestamp with time zone,
    ip_aceptacion character varying(50) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_aceptacion_condiciones
    OWNER to w4ll4c3;