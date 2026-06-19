-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.numerales_contrato

-- DROP TABLE IF EXISTS public.numerales_contrato;

CREATE TABLE IF NOT EXISTS public.numerales_contrato
(
    numeral_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    contrato_id integer,
    numeral integer,
    texto_contrato text COLLATE pg_catalog."default",
    CONSTRAINT pk_numerales_contrato PRIMARY KEY (numeral_id),
    CONSTRAINT fk_numerales_contrato_reference_condiciones_servicio FOREIGN KEY (contrato_id)
        REFERENCES public.condiciones_servicio (contrato_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;


