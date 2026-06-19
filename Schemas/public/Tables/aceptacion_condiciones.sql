-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.aceptacion_condiciones

-- DROP TABLE IF EXISTS public.aceptacion_condiciones;

CREATE TABLE IF NOT EXISTS public.aceptacion_condiciones
(
    aceptacion_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint NOT NULL,
    contrato_id integer,
    numeral_contrato integer,
    fecha_aceptacion timestamp with time zone,
    ip_aceptacion character varying(50) COLLATE pg_catalog."default",
    CONSTRAINT pk_aceptacion_condiciones PRIMARY KEY (aceptacion_id),
    CONSTRAINT fk_aceptacion_condiciones_reference_condiciones_servicio FOREIGN KEY (contrato_id)
        REFERENCES public.condiciones_servicio (contrato_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_aceptacion_condiciones_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;


