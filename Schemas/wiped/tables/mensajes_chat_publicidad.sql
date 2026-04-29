-- Table: wiped.mensajes_chat_publicidad

-- DROP TABLE IF EXISTS wiped.mensajes_chat_publicidad;

CREATE TABLE IF NOT EXISTS wiped.mensajes_chat_publicidad
(
    mensaje_id bigint,
    chat_id bigint,
    remitente_persona_id bigint,
    contenido text COLLATE pg_catalog."default",
    fecha_envio timestamp with time zone,
    leido boolean,
    fecha_lectura timestamp with time zone,
    url_media character varying(500) COLLATE pg_catalog."default",
    tipo_media character varying(20) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

