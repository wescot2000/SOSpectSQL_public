-- Table: migracion.migra_metricas_politico
-- CREADO: 2026-04-25 - Migración de métricas históricas por político para análisis de desempeño en el tiempo

-- DROP TABLE IF EXISTS migracion.migra_metricas_politico;

CREATE TABLE IF NOT EXISTS migracion.migra_metricas_politico
(
    id bigint,
    politico_id integer,
    fecha_desde_alarmas timestamp with time zone,
    fecha_hasta_alarmas timestamp with time zone,
    cnt_total integer,
    cnt_abiertas integer,
    cnt_cerradas integer,
    pct_resolucion numeric(5,1),
    cnt_likes integer,
    cnt_reenvios integer,
    avg_dias_resolucion numeric(8,1),
    cnt_cierres_con_fecha integer,
    tipos_alarma jsonb,
    fecha_inicio_vigencia timestamp with time zone,
    fecha_fin_vigencia timestamp with time zone,
    fecha_calculo timestamp with time zone,
    score_gestion numeric(5,1)
)

TABLESPACE pg_default;
