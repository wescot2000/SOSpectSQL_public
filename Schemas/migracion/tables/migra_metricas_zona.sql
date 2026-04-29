-- Table: migracion.migra_metricas_zona
-- CREADO: 2026-04-25 - Migración de métricas de zona para análisis histórico de puntos calientes

-- DROP TABLE IF EXISTS migracion.migra_metricas_zona;

CREATE TABLE IF NOT EXISTS migracion.migra_metricas_zona
(
    id bigint,
    celda_lat numeric(7,4),
    celda_lon numeric(7,4),
    fecha_desde_alarmas timestamp with time zone,
    fecha_hasta_alarmas timestamp with time zone,
    tipos_alarma jsonb,
    cnt_total integer,
    cnt_ciertas integer,
    cnt_falsas integer,
    pct_ciertas numeric(5,1),
    avg_minutos_calificacion numeric(8,1),
    cnt_capturas integer,
    cnt_personas_en_zona integer,
    fecha_inicio_vigencia timestamp with time zone,
    fecha_fin_vigencia timestamp with time zone,
    fecha_calculo timestamp with time zone
)

TABLESPACE pg_default;
