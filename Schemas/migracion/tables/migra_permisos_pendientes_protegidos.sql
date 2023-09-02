-- Table: migracion.migra_permisos_pendientes_protegidos

-- DROP TABLE IF EXISTS migracion.migra_permisos_pendientes_protegidos;

CREATE TABLE IF NOT EXISTS migracion.migra_permisos_pendientes_protegidos
(
    permiso_pendiente_id bigint,
    persona_id_protector bigint,
    persona_id_protegido bigint,
    tiempo_subscripcion_dias integer,
    fecha_solicitud timestamp with time zone,
    flag_aprobado boolean,
    fecha_aprobado timestamp with time zone,
    tiporelacion_id integer
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_permisos_pendientes_protegidos
    OWNER to w4ll4c3;