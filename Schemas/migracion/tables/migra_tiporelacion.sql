-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_tiporelacion

-- DROP TABLE IF EXISTS migracion.migra_tiporelacion;

CREATE TABLE IF NOT EXISTS migracion.migra_tiporelacion
(
    tiporelacion_id integer,
    descripciontiporel character varying(150) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;


