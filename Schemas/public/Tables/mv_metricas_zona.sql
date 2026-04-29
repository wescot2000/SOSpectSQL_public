-- TABLE: public.mv_metricas_zona
-- Caché de lectura rápida de métricas de zona para los 3 reportes básicos de la API.
-- Una fila por celda geoespacial de 0.01° × 0.01° (~1.1 km).
--
-- Flujo de actualización:
--   refrescar_metricas_zona() calcula el delta incremental, lo guarda en
--   metricas_zona (SCD Tipo 2) y luego sincroniza esta tabla con los valores vigentes.
--
-- La API lee desde ESTA tabla:
--   1. Recibe la última ubicación del usuario (lat, lon).
--   2. Calcula la celda: celda_lat = ROUND(lat/0.01)*0.01, celda_lon = ROUND(lon/0.01)*0.01
--   3. SELECT * FROM mv_metricas_zona WHERE celda_lat = ? AND celda_lon = ?
--   → Retorno O(1), sin agregaciones en tiempo real.
--
-- Endpoints que la consumen (ReportesController.cs):
--   GET /Reportes/ListarParticipacionTipoAlarma   → tipos_alarma (jsonb)
--   GET /Reportes/ObtenerPromedioEfectivoAlarmas  → cnt_total, cnt_ciertas, cnt_falsas, pct_ciertas
--   GET /Reportes/ListaMetricasBasicas            → avg_minutos_calificacion, cnt_capturas, cnt_personas_en_zona
--
-- Se refresca con: CALL public.refrescar_metricas_zona()
-- Cron diario (tras refrescar_metricas_politico):
--   SELECT cron.schedule('Metricas zona', '5 0 * * *', 'CALL public.refrescar_metricas_zona()');
--
-- Creado: 2026-04-07
--

CREATE TABLE IF NOT EXISTS public.mv_metricas_zona (
    celda_lat                NUMERIC(7,4)  NOT NULL,
    celda_lon                NUMERIC(7,4)  NOT NULL,

    -- Distribución por tipo de alarma (reporte BasicReportTiposAlarma)
    tipos_alarma             JSONB,

    -- Efectividad (reporte BasicReportEfectividadAlarmas)
    cnt_total                INTEGER       NOT NULL DEFAULT 0,
    cnt_ciertas              INTEGER       NOT NULL DEFAULT 0,
    cnt_falsas               INTEGER       NOT NULL DEFAULT 0,
    pct_ciertas              NUMERIC(5,1),

    -- Métricas básicas (reporte BasicReportMetricasBasicas)
    avg_minutos_calificacion NUMERIC(8,1),
    cnt_capturas             INTEGER       NOT NULL DEFAULT 0,
    cnt_personas_en_zona     INTEGER       NOT NULL DEFAULT 0,

    -- Auditoría
    fecha_calculo            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_mv_metricas_zona_pk UNIQUE (celda_lat, celda_lon)
);

-- Índice geoespacial en cuadrícula para lookup O(1)
CREATE INDEX IF NOT EXISTS idx_mv_metricas_zona_celda
    ON public.mv_metricas_zona(celda_lat, celda_lon);

COMMENT ON TABLE public.mv_metricas_zona IS
'Caché de lectura rápida de métricas por celda geoespacial (0.01°×0.01°, ~1.1 km). Una fila por celda. Sincronizada diariamente por refrescar_metricas_zona() desde metricas_zona (SCD Tipo 2). Reemplaza las funciones ConsultaParticipacionTiposAlarma, MetricasAlarmasEnZona y MetricasSueltasBasicas en los endpoints de la API para evitar queries pesadas en tiempo real. Creado: 2026-04-07.';
