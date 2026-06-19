-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.radio_alarmas

-- DROP TABLE IF EXISTS public.radio_alarmas;

CREATE TABLE IF NOT EXISTS public.radio_alarmas
(
    radio_alarmas_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    radio_mts integer NOT NULL,
    radio_double numeric(8,6) NOT NULL,
    poderes_consumidos integer,
    CONSTRAINT pk_radio_alarmas PRIMARY KEY (radio_alarmas_id)
)

TABLESPACE pg_default;


