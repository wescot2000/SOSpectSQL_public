-- Table: public.descripcionesalarmas

-- DROP TABLE IF EXISTS public.descripcionesalarmas;

CREATE TABLE IF NOT EXISTS public.descripcionesalarmas
(
    iddescripcion bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    alarma_id bigint NOT NULL,
    persona_id bigint NOT NULL,
    descripcionalarma character varying(500) COLLATE pg_catalog."default",
    descripcionsospechoso character varying(500) COLLATE pg_catalog."default",
    descripcionvehiculo character varying(500) COLLATE pg_catalog."default",
    descripcionarmas character varying(500) COLLATE pg_catalog."default",
    fechadescripcion timestamp with time zone NOT NULL,
    calificaciondescripcion smallint,
    veracidadalarma boolean,
    flageditado boolean DEFAULT false,
    latitud_originador numeric(9,6),
    longitud_originador numeric(9,6),
    ip_usuario_originador character varying(50) COLLATE pg_catalog."default",
    distancia_alarma_originador numeric(9,2),
    idioma_origen character varying(10) COLLATE pg_catalog."default",
    CONSTRAINT pk_descripcionesalarmas PRIMARY KEY (iddescripcion),
    CONSTRAINT fk_descripc_reference_alarmas FOREIGN KEY (alarma_id)
        REFERENCES public.alarmas (alarma_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_descripc_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.descripcionesalarmas
    OWNER to w4ll4c3;