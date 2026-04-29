-- Table: migracion.migra_metricas_emprendedores
-- CREADO: 2026-04-25 - Migración de métricas históricas de emprendedores para análisis de tendencias alza/baja

-- DROP TABLE IF EXISTS migracion.migra_metricas_emprendedores;

CREATE TABLE IF NOT EXISTS migracion.migra_metricas_emprendedores
(
    id bigint,
    pais character varying(100) COLLATE pg_catalog."default",
    id_emprendimiento bigint,
    nombre_emprendimiento character varying(500) COLLATE pg_catalog."default",
    reputacion_promedio numeric(3,2),
    total_calificaciones integer,
    promedio_tiempo_respuesta_minutos integer,
    porcentaje_satisfaccion numeric(5,2),
    total_chats_mes_actual integer,
    total_transacciones_exitosas integer,
    badges_ganados jsonb,
    puesto_en_pais integer,
    fecha_inicio_vigencia timestamp with time zone,
    fecha_fin_vigencia timestamp with time zone,
    fecha_calculo timestamp with time zone
)

TABLESPACE pg_default;
