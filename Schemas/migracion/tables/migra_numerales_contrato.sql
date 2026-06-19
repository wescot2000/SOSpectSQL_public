-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_numerales_contrato

-- DROP TABLE IF EXISTS migracion.migra_numerales_contrato;

CREATE TABLE IF NOT EXISTS migracion.migra_numerales_contrato
(
    numeral_id integer,
    contrato_id integer,
    numeral integer,
    texto_contrato text COLLATE pg_catalog."default"
)

TABLESPACE pg_default;


