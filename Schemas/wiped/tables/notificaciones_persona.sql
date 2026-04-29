-- Table: wiped.notificaciones_persona

-- DROP TABLE IF EXISTS wiped.notificaciones_persona;

CREATE TABLE IF NOT EXISTS wiped.notificaciones_persona
(
    notificacion_id bigint,
    persona_id bigint,
    alarma_id bigint,
    flag_enviado boolean,
    fecha_notificacion timestamp with time zone,
    ultima_notificacion_enviada timestamp with time zone
)

TABLESPACE pg_default;
