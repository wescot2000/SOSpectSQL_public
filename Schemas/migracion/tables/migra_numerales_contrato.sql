-- Table: migracion.migra_numerales_contrato

-- DROP TABLE IF EXISTS migracion.migra_numerales_contrato;

CREATE TABLE IF NOT EXISTS migracion.migra_numerales_contrato
(
    numeral_id integer,
    contrato_id integer,
    numeral integer,
    texto_contrato character varying(500) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_numerales_contrato
    OWNER to w4ll4c3;