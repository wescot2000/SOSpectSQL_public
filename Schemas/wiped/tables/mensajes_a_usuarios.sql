-- Table: wiped.mensajes_a_usuarios

-- DROP TABLE IF EXISTS wiped.mensajes_a_usuarios;

CREATE TABLE IF NOT EXISTS wiped.mensajes_a_usuarios
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
    alarma_id bigint,
    tipoalarma_id integer,
    descripcion_alarma character varying(500) COLLATE pg_catalog."default",
    url_foto character varying(500) COLLATE pg_catalog."default",
    distancia_metros integer,
    url_logo character varying(500) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;
