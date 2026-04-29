-- Table: migracion.migra_mv_metricas_politico
-- CREADO: 2026-04-25 - Migración de snapshot actual de métricas por político (vista materializada)

-- DROP TABLE IF EXISTS migracion.migra_mv_metricas_politico;

CREATE TABLE IF NOT EXISTS migracion.migra_mv_metricas_politico
(
    politico_id integer,
    cnt_total integer,
    cnt_abiertas integer,
    cnt_cerradas integer,
    pct_resolucion numeric(5,1),
    cnt_likes integer,
    cnt_reenvios integer,
    avg_dias_resolucion numeric(8,1),
    fecha_calculo timestamp with time zone,
    pct_aprobacion numeric(5,1),
    cnt_votantes_aprobacion integer,
    score_gestion numeric(5,1)
)

TABLESPACE pg_default;
