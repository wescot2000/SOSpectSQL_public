-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: wiped.calificadores_descripcion

-- DROP TABLE IF EXISTS wiped.calificadores_descripcion;

CREATE TABLE IF NOT EXISTS wiped.calificadores_descripcion
(
    calificacion_id bigint,
    iddescripcion bigint,
    persona_id bigint,
    calificacion character varying(50) COLLATE pg_catalog."default",
    fecha_calificacion timestamp with time zone
)

TABLESPACE pg_default;


