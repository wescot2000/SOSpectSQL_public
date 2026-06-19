-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.valorsubscripciones

-- DROP TABLE IF EXISTS public.valorsubscripciones;

CREATE TABLE IF NOT EXISTS public.valorsubscripciones
(
    valorsubscripcion_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    tipo_subscr_id integer NOT NULL,
    cantidad_subscripcion integer,
    cantidad_poderes integer NOT NULL,
    tiempo_subscripcion_horas integer,
    CONSTRAINT pk_valorsubscripciones PRIMARY KEY (valorsubscripcion_id)
)

TABLESPACE pg_default;


