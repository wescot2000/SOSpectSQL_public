-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.poderes

-- DROP TABLE IF EXISTS public.poderes;

CREATE TABLE IF NOT EXISTS public.poderes
(
    poder_id integer NOT NULL,
    cantidad integer,
    valor_cop integer,
    valor_usd numeric(5,2),
    fecha_inicio timestamp with time zone,
    fecha_fin timestamp with time zone,
    "ProductId" character varying(200) COLLATE pg_catalog."default",
    CONSTRAINT pk_poderes PRIMARY KEY (poder_id)
)

TABLESPACE pg_default;


