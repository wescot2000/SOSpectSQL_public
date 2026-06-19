-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_valorsubscripciones

-- DROP TABLE IF EXISTS migracion.migra_valorsubscripciones;

CREATE TABLE IF NOT EXISTS migracion.migra_valorsubscripciones
(
    valorsubscripcion_id integer,
    tipo_subscr_id integer,
    cantidad_subscripcion integer,
    cantidad_poderes integer,
    tiempo_subscripcion_horas integer
)

TABLESPACE pg_default;


