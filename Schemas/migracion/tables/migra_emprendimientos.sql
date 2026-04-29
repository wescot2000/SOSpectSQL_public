-- Table: migracion.migra_emprendimientos
-- CREADO: 2026-04-25 - Migración de perfiles de emprendimientos para análisis histórico de tendencias

-- DROP TABLE IF EXISTS migracion.migra_emprendimientos;

CREATE TABLE IF NOT EXISTS migracion.migra_emprendimientos
(
    id_emprendimiento bigint,
    persona_id_modificadora bigint,
    nombre_emprendimiento character varying(500) COLLATE pg_catalog."default",
    nit_cedula_propietario character varying(80) COLLATE pg_catalog."default",
    nombre_propietario character varying(500) COLLATE pg_catalog."default",
    url_logo character varying(500) COLLATE pg_catalog."default",
    flag_es_usuario_propietario boolean,
    fecha_inicio timestamp with time zone,
    fecha_fin timestamp with time zone,
    reputacion_promedio numeric(3,2),
    total_calificaciones integer,
    promedio_tiempo_respuesta_minutos integer,
    promedio_tiempo_entrega_horas integer,
    porcentaje_satisfaccion numeric(5,2),
    total_chats_mes_actual integer,
    total_transacciones_exitosas integer,
    badges_ganados jsonb,
    fecha_actualizacion_metricas timestamp with time zone
)

TABLESPACE pg_default;
