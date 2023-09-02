-- Table: migracion.migra_mensajes_a_usuarios

-- DROP TABLE IF EXISTS migracion.migra_mensajes_a_usuarios;

CREATE TABLE IF NOT EXISTS migracion.migra_mensajes_a_usuarios
(
    mensaje_id bigint,
    persona_id bigint,
    texto character varying(500) COLLATE pg_catalog."default",
    fecha_mensaje timestamp with time zone,
    estado boolean,
    asunto character varying(500) COLLATE pg_catalog."default",
    idioma_origen character varying(10) COLLATE pg_catalog."default",
    texto_traducido character varying(500) COLLATE pg_catalog."default",
    idioma_post_traduccion character varying(10) COLLATE pg_catalog."default",
    fecha_traduccion timestamp with time zone,
    asunto_traducido character varying(500) COLLATE pg_catalog."default",
    alarma_id bigint
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_mensajes_a_usuarios
    OWNER to w4ll4c3;