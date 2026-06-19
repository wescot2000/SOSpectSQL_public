-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_dispositivos

-- DROP TABLE IF EXISTS migracion.migra_dispositivos;

CREATE TABLE IF NOT EXISTS migracion.migra_dispositivos
(
    id_dispositivo bigint,
    persona_id bigint,
    registrationid character varying(200) COLLATE pg_catalog."default",
    plataforma character varying(100) COLLATE pg_catalog."default",
    idioma character varying(10) COLLATE pg_catalog."default",
    fecha_inicio timestamp with time zone,
    fecha_fin timestamp with time zone,
    pais_id character varying(3) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;


