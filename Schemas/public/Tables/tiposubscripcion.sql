-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.tiposubscripcion

-- DROP TABLE IF EXISTS public.tiposubscripcion;

CREATE TABLE IF NOT EXISTS public.tiposubscripcion
(
    tipo_subscr_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    descripcion_tipo character varying(100) COLLATE pg_catalog."default",
    CONSTRAINT pk_tiposubscripcion PRIMARY KEY (tipo_subscr_id)
)

TABLESPACE pg_default;


