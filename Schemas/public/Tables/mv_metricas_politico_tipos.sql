-- Table: public.mv_metricas_politico_tipos
-- Módulo político: distribución de alarmas por tipo para cada político vigente.
-- Creado: 2026-03-09
--
-- Tabla auxiliar gestionada por el procedure public.refrescar_metricas_politico().
-- No es una vista materializada porque las MV no soportan fácilmente filas múltiples
-- por grupo con REFRESH CONCURRENTLY.
--
-- Una fila por (politico_id, tipoalarma_id).
-- Se vacía y recarga con cada llamada a refrescar_metricas_politico().

CREATE TABLE IF NOT EXISTS public.mv_metricas_politico_tipos
(
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    politico_id     INTEGER     NOT NULL,
    tipoalarma_id   BIGINT      NOT NULL,
    cnt             INTEGER     NOT NULL DEFAULT 0,
    pct             NUMERIC(5,1),   -- Porcentaje del total del político; NULL si total=0
    CONSTRAINT uq_mv_metricas_politico_tipos UNIQUE (politico_id, tipoalarma_id)
);

COMMENT ON TABLE public.mv_metricas_politico_tipos IS
'Distribución de alarmas por tipo para cada político. Actualizada por refrescar_metricas_politico(). Una fila por (politico_id, tipoalarma_id).';

CREATE INDEX IF NOT EXISTS idx_mv_metricas_tipos_politico
    ON public.mv_metricas_politico_tipos(politico_id);
