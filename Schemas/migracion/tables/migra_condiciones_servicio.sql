-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

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


