-- Table: migracion.migra_mv_metricas_zona
-- CREADO: 2026-04-25 - Migración de snapshot actual de métricas de zona (vista materializada)

-- DROP TABLE IF EXISTS migracion.migra_mv_metricas_zona;

CREATE TABLE IF NOT EXISTS migracion.migra_mv_metricas_zona
(
    celda_lat numeric(7,4),
    celda_lon numeric(7,4),
    tipos_alarma jsonb,
    cnt_total integer,
    cnt_ciertas integer,
    cnt_falsas integer,
    pct_ciertas numeric(5,1),
    avg_minutos_calificacion numeric(8,1),
    cnt_capturas integer,
    cnt_personas_en_zona integer,
    fecha_calculo timestamp with time zone
)

TABLESPACE pg_default;
