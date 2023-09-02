-- Table: migracion.migra_traducciones_contrato

-- DROP TABLE IF EXISTS migracion.migra_traducciones_contrato;

CREATE TABLE IF NOT EXISTS migracion.migra_traducciones_contrato
(
    traduccion_id integer,
    contrato_id integer,
    texto_traducido character varying(50000) COLLATE pg_catalog."default",
    idioma character varying(10) COLLATE pg_catalog."default",
    fecha_traduccion timestamp with time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_traducciones_contrato
    OWNER to w4ll4c3;