-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.tiporelacion

-- DROP TABLE IF EXISTS public.tiporelacion;

CREATE TABLE IF NOT EXISTS public.tiporelacion
(
    tiporelacion_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    descripciontiporel character varying(150) COLLATE pg_catalog."default",
    CONSTRAINT pk_tiporelacion PRIMARY KEY (tiporelacion_id)
)

TABLESPACE pg_default;


