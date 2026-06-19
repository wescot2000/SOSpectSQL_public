-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_notificaciones_promociones
-- CREADO: 2026-04-25 - Migración de notificaciones push de promociones para análisis de efectividad de campañas

-- DROP TABLE IF EXISTS migracion.migra_notificaciones_promociones;

CREATE TABLE IF NOT EXISTS migracion.migra_notificaciones_promociones
(
    id_notificacion_promocion bigint,
    subscripcion_id bigint,
    user_id_thirdparty character varying(150) COLLATE pg_catalog."default",
    envio_aceptado_firebase boolean,
    error_code character varying(50) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;


