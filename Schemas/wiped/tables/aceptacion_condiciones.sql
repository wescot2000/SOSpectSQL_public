-- Table: wiped.aceptacion_condiciones

-- DROP TABLE IF EXISTS wiped.aceptacion_condiciones;

CREATE TABLE IF NOT EXISTS wiped.aceptacion_condiciones
(
    aceptacion_id bigint,
    persona_id bigint,
    contrato_id integer,
    numeral_contrato integer,
    fecha_aceptacion timestamp with time zone,
    ip_aceptacion character varying(50) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;
