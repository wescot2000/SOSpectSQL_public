-- TABLE: public.mv_metricas_politico
-- Módulo político: caché de lectura rápida de métricas de desempeño por político.
-- Creado: 2026-03-09 | Modificado: 2026-04-23
--
-- IMPORTANTE: Esta tabla ya NO es una Materialized View.
-- Fue convertida a tabla regular para soportar la arquitectura incremental
-- donde la fuente de verdad es public.metricas_politico (SCD Tipo 2).
--
-- Flujo de actualización:
--   refrescar_metricas_politico() calcula el delta incremental, lo guarda en
--   metricas_politico y luego sincroniza esta tabla (INSERT ... ON CONFLICT DO UPDATE)
--   con los valores vigentes (fecha_fin_vigencia IS NULL).
--
-- La API lee desde ESTA tabla (sin cambios en PoliticosController.cs ni en
-- vw_autoridades_por_alarma).
--
-- Se refresca con: CALL public.refrescar_metricas_politico()
-- Cron diario a las 0:00 UTC:
--   SELECT cron.schedule('Metricas politicos', '0 0 * * *', 'CALL public.refrescar_metricas_politico()');
--
-- La tabla auxiliar mv_metricas_politico_tipos está en Tables/mv_metricas_politico_tipos.sql
-- ════════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.mv_metricas_politico (
    politico_id           INTEGER      NOT NULL,
    cnt_total             INTEGER      NOT NULL DEFAULT 0,
    cnt_abiertas          INTEGER      NOT NULL DEFAULT 0,
    cnt_cerradas          INTEGER      NOT NULL DEFAULT 0,
    pct_resolucion        NUMERIC(5,1),
    cnt_likes             INTEGER      NOT NULL DEFAULT 0,
    cnt_reenvios          INTEGER      NOT NULL DEFAULT 0,
    avg_dias_resolucion   NUMERIC(8,1),
    fecha_calculo         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    pct_aprobacion        NUMERIC(5,1),
    cnt_votantes_aprobacion INTEGER      NOT NULL DEFAULT 0,
    -- Score de gestión ponderado (0–100). Combina pct_resolucion excluyendo falsas alarmas,
    -- penalización por alarmas abiertas (días × viralidad, máx -40 pts) y
    -- premio por cierres (viralidad del cierre, máx +10 pts).
    score_gestion         NUMERIC(5,1),
    CONSTRAINT uq_mv_metricas_politico_pk UNIQUE (politico_id)
);

-- Índice de rendimiento para búsquedas por tasa de resolución
CREATE INDEX IF NOT EXISTS idx_mv_metricas_politico_pct
    ON public.mv_metricas_politico(pct_resolucion);

-- Índice para ranking por score_gestion (métrica principal del endpoint ObtenerRankingPoliticos)
CREATE INDEX IF NOT EXISTS idx_mv_metricas_politico_score
    ON public.mv_metricas_politico(score_gestion);

COMMENT ON TABLE public.mv_metricas_politico IS
'Caché de lectura rápida de métricas de desempeño por político. Una fila por político (UNIQUE politico_id). Sincronizada diariamente por refrescar_metricas_politico() desde public.metricas_politico (SCD Tipo 2). La API y vw_autoridades_por_alarma leen desde aquí. Convertida de Materialized View a tabla regular el 2026-03-10 para soportar cálculo incremental ETL-aware.';
