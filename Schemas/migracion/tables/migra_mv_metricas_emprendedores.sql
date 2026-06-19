-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: migracion.migra_mv_metricas_emprendedores
-- CREADO: 2026-04-25 - Migración de snapshot actual de métricas de emprendedores (vista materializada)

-- DROP TABLE IF EXISTS migracion.migra_mv_metricas_emprendedores;

CREATE TABLE IF NOT EXISTS migracion.migra_mv_metricas_emprendedores
(
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
    total_emprendedores_en_pais integer,
    fecha_calculo timestamp with time zone
)

TABLESPACE pg_default;


