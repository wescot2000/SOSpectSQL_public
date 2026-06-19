-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.transacciones_personas

-- DROP TABLE IF EXISTS public.transacciones_personas;

CREATE TABLE IF NOT EXISTS public.transacciones_personas
(
    transaccion_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint NOT NULL,
    poder_id integer,
    fecha_transaccion timestamp with time zone,
    ip_transaccion character varying(150) COLLATE pg_catalog."default" NOT NULL,
    tipo_transaccion character varying(50) COLLATE pg_catalog."default",
    purchase_token character varying(5000) COLLATE pg_catalog."default",
    CONSTRAINT pk_transacciones_personas PRIMARY KEY (transaccion_id),
    CONSTRAINT fk_transacciones_personas_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;


