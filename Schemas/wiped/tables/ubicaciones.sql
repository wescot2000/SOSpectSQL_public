-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: wiped.ubicaciones

-- DROP TABLE IF EXISTS wiped.ubicaciones;

CREATE TABLE IF NOT EXISTS wiped.ubicaciones
(
    ubicacion_id bigint,
    persona_id bigint,
    latitud numeric(9,6),
    longitud numeric(9,6),
    "Tipo" character varying(1) COLLATE pg_catalog."default",
    pais_id character varying(3) COLLATE pg_catalog."default"
    
)

TABLESPACE pg_default;


