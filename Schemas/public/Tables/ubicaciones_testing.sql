-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.ubicaciones_testing

-- DROP TABLE IF EXISTS public.ubicaciones_testing;

CREATE TABLE IF NOT EXISTS public.ubicaciones_testing
(
    ubicacion_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint,
    latitud numeric(9,6),
    longitud numeric(9,6),
    fecha_ubicacion timestamp with time zone,
    pais_id character varying(3) COLLATE pg_catalog."default",
    CONSTRAINT pk_ubicaciones_testing PRIMARY KEY (ubicacion_id)
)

TABLESPACE pg_default;


