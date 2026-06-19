-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_tiposubscripcion

-- DROP TABLE IF EXISTS migracion.migra_tiposubscripcion;

CREATE TABLE IF NOT EXISTS migracion.migra_tiposubscripcion
(
    tipo_subscr_id integer,
    descripcion_tipo character varying(100) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;


