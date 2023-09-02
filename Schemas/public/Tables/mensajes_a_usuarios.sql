-- Table: public.mensajes_a_usuarios

-- DROP TABLE IF EXISTS public.mensajes_a_usuarios;

CREATE TABLE IF NOT EXISTS public.mensajes_a_usuarios
(
    mensaje_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint NOT NULL,
    texto character varying(500) COLLATE pg_catalog."default",
    fecha_mensaje timestamp with time zone,
    estado boolean NOT NULL,
    asunto character varying(500) COLLATE pg_catalog."default",
    idioma_origen character varying(10) COLLATE pg_catalog."default" NOT NULL,
    texto_traducido character varying(500) COLLATE pg_catalog."default",
    idioma_post_traduccion character varying(10) COLLATE pg_catalog."default",
    fecha_traduccion timestamp with time zone,
    asunto_traducido character varying(500) COLLATE pg_catalog."default",
    alarma_id bigint,
    CONSTRAINT pk_mensajes_a_usuarios2 PRIMARY KEY (mensaje_id),
    CONSTRAINT fk_mensajes_a_alarmas FOREIGN KEY (alarma_id)
        REFERENCES public.alarmas (alarma_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID,
    CONSTRAINT fk_mensajes_a_usuarios_reference_personas2 FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.mensajes_a_usuarios
    OWNER to w4ll4c3;