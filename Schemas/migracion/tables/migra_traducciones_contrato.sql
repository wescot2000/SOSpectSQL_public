-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

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


