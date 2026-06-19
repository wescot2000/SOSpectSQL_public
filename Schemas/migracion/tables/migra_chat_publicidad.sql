-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_chat_publicidad
-- CREADO: 2026-04-25 - Migración de chats de publicidad cerrados/archivados para análisis de ventas de emprendedores

-- DROP TABLE IF EXISTS migracion.migra_chat_publicidad;

CREATE TABLE IF NOT EXISTS migracion.migra_chat_publicidad
(
    chat_id bigint,
    alarma_id bigint,
    proveedor_persona_id bigint,
    interesado_persona_id bigint,
    fecha_inicio timestamp with time zone,
    estado character varying(20) COLLATE pg_catalog."default",
    fecha_estado_cambio timestamp with time zone,
    interesado_acepto_terminos boolean,
    fecha_interesado_acepto timestamp with time zone,
    subscripcion_id bigint,
    calificacion_servicio integer,
    comentario_cliente text,
    fecha_calificacion timestamp with time zone,
    fecha_primera_respuesta_proveedor timestamp with time zone,
    fecha_entrega_confirmada timestamp with time zone
)

TABLESPACE pg_default;


