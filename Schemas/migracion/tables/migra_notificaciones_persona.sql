-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_notificaciones_persona

-- DROP TABLE IF EXISTS migracion.migra_notificaciones_persona;

CREATE TABLE IF NOT EXISTS migracion.migra_notificaciones_persona
(
    notificacion_id bigint,
    persona_id bigint,
    alarma_id bigint,
    flag_enviado boolean,
    fecha_notificacion timestamp with time zone,
    ultima_notificacion_enviada timestamp with time zone
)

TABLESPACE pg_default;

ALTER TABLE migracion.migra_notificaciones_persona
ADD COLUMN fecha_tap_notificacion timestamp with time zone;


