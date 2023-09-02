-- Table: public.alarmas

-- DROP TABLE IF EXISTS public.alarmas;

CREATE TABLE IF NOT EXISTS public.alarmas
(
    alarma_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint NOT NULL,
    tipoalarma_id integer NOT NULL,
    fecha_alarma timestamp with time zone NOT NULL,
    latitud numeric(9,6) NOT NULL,
    longitud numeric(9,6) NOT NULL,
    calificacion_alarma numeric(5,2),
    estado_alarma character varying(1) COLLATE pg_catalog."default",
    latitud_originador numeric(9,6),
    longitud_originador numeric(9,6),
    ip_usuario_originador character varying(50) COLLATE pg_catalog."default",
    distancia_alarma_originador numeric(9,2),
    alarma_id_padre bigint,
    CONSTRAINT pk_alarmas PRIMARY KEY (alarma_id),
    CONSTRAINT fk_alarmas_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.alarmas
    OWNER to w4ll4c3;