-- Table: public.calificadores_descripcion

-- DROP TABLE IF EXISTS public.calificadores_descripcion;

CREATE TABLE IF NOT EXISTS public.calificadores_descripcion
(
    calificacion_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    iddescripcion bigint NOT NULL,
    persona_id bigint NOT NULL,
    calificacion character varying(50) COLLATE pg_catalog."default",
    fecha_calificacion timestamp with time zone NOT NULL,
    CONSTRAINT pk_calificadores_descripcion2 PRIMARY KEY (calificacion_id),
    CONSTRAINT fk_calificadores_descripcion_reference_descripcionesalarmas2 FOREIGN KEY (iddescripcion)
        REFERENCES public.descripcionesalarmas (iddescripcion) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_calificadores_descripcion_reference_personas2 FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.calificadores_descripcion
    OWNER to w4ll4c3;