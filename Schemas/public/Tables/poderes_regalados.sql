-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.poderes_regalados

-- DROP TABLE IF EXISTS public.poderes_regalados;

CREATE TABLE IF NOT EXISTS public.poderes_regalados
(
    id_regalo bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint NOT NULL,
    cantidad_poderes_regalada integer,
    fecha_regalo timestamp with time zone,
    calificaciones_negativas integer,
    promedio_veracidad numeric(5,4),
    CONSTRAINT pk_poderes_regalados PRIMARY KEY (id_regalo),
    CONSTRAINT fk_poderes_regalados_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;


