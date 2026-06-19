-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.idiomaspendientesagregar

-- DROP TABLE IF EXISTS public.idiomaspendientesagregar;

CREATE TABLE IF NOT EXISTS public.idiomaspendientesagregar
(
    registro_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    idioma character varying(10) COLLATE pg_catalog."default",
    clave character varying(255) COLLATE pg_catalog."default",
    cantidad_ocurrencias integer,
    CONSTRAINT unique_idioma_procedure UNIQUE (idioma, clave)
)

TABLESPACE pg_default;


