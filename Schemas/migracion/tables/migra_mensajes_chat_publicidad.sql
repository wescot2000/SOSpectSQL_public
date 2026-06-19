-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_mensajes_chat_publicidad
-- CREADO: 2026-04-25 - Migración de mensajes de chats archivados para análisis de volumen de interacción

-- DROP TABLE IF EXISTS migracion.migra_mensajes_chat_publicidad;

CREATE TABLE IF NOT EXISTS migracion.migra_mensajes_chat_publicidad
(
    mensaje_id bigint,
    chat_id bigint,
    remitente_persona_id bigint,
    contenido text,
    fecha_envio timestamp with time zone,
    leido boolean,
    fecha_lectura timestamp with time zone,
    url_media character varying(500) COLLATE pg_catalog."default",
    tipo_media character varying(20) COLLATE pg_catalog."default",
    idioma_origen character varying(10) COLLATE pg_catalog."default",
    contenido_traducido text,
    idioma_traduccion character varying(10) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;


