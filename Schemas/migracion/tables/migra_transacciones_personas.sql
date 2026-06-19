-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_transacciones_personas

-- DROP TABLE IF EXISTS migracion.migra_transacciones_personas;

CREATE TABLE IF NOT EXISTS migracion.migra_transacciones_personas
(
    transaccion_id bigint,
    persona_id bigint,
    poder_id integer,
    fecha_transaccion timestamp with time zone,
    ip_transaccion character varying(150) COLLATE pg_catalog."default",
    tipo_transaccion character varying(50) COLLATE pg_catalog."default",
    purchase_token character varying(5000) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;


