-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.dispositivos

-- DROP TABLE IF EXISTS public.dispositivos;

CREATE TABLE IF NOT EXISTS public.dispositivos
(
    id_dispositivo bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint NOT NULL,
    registrationid character varying(200) COLLATE pg_catalog."default" NOT NULL,
    plataforma character varying(100) COLLATE pg_catalog."default",
    idioma character varying(10) COLLATE pg_catalog."default" NOT NULL,
    fecha_inicio timestamp with time zone,
    fecha_fin timestamp with time zone,
    pais_id character varying(3) COLLATE pg_catalog."default",
    CONSTRAINT pk_dispositivos PRIMARY KEY (id_dispositivo),
    CONSTRAINT fk_dispositivos_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;


