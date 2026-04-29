-- TABLE: public.metricas_zona
-- Métricas de reportes básicos precalculadas por celda geoespacial de 0.01° × 0.01° (~1.1 km).
-- Diseño SCD Tipo 2: cada ejecución diaria cierra el registro vigente e inserta uno nuevo,
-- preservando el historial completo de evolución de los KPIs por zona.
--
-- El registro vigente de cada celda es el que tiene fecha_fin_vigencia IS NULL.
--
-- Esta tabla es interna; la API NO la consulta directamente. El procedure
-- refrescar_metricas_zona() la mantiene y sincroniza los resultados hacia
-- la tabla de caché public.mv_metricas_zona (leída por la API).
--
-- Creado: 2026-04-07
--

CREATE TABLE IF NOT EXISTS public.metricas_zona (
    id                       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Identificador de celda geoespacial (cuadrícula 0.01° × 0.01°, ~1.1 km)
    -- Se calcula como ROUND(latitud / 0.01) * 0.01 y ROUND(longitud / 0.01) * 0.01
    celda_lat                NUMERIC(7,4)  NOT NULL,
    celda_lon                NUMERIC(7,4)  NOT NULL,

    -- Rango de alarmas consideradas en el cálculo acumulado
    fecha_desde_alarmas      TIMESTAMPTZ   NOT NULL,
    fecha_hasta_alarmas      TIMESTAMPTZ   NOT NULL,

    -- Distribución por tipo de alarma (espejo del reporte BasicReportTiposAlarma)
    -- Formato: [{"tipoalarma_id": 1, "cnt": 42, "pct": 55.3}, ...]
    tipos_alarma             JSONB,

    -- Métricas de efectividad (reporte BasicReportEfectividadAlarmas)
    -- Excluye alarmas falsas (calificacion_alarma < 50)
    cnt_total                INTEGER       NOT NULL DEFAULT 0,
    cnt_ciertas              INTEGER       NOT NULL DEFAULT 0,
    cnt_falsas               INTEGER       NOT NULL DEFAULT 0,
    pct_ciertas              NUMERIC(5,1),

    -- Métricas básicas de zona (reporte BasicReportMetricasBasicas)
    avg_minutos_calificacion NUMERIC(8,1),   -- promedio de minutos hasta primera calificación
    cnt_capturas             INTEGER       NOT NULL DEFAULT 0,
    cnt_personas_en_zona     INTEGER       NOT NULL DEFAULT 0,

    -- Control SCD Tipo 2
    fecha_inicio_vigencia    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    fecha_fin_vigencia       TIMESTAMPTZ,   -- NULL = registro vigente

    -- Auditoría
    fecha_calculo            TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- Índice único parcial: garantiza un solo registro vigente por celda
CREATE UNIQUE INDEX IF NOT EXISTS idx_metricas_zona_vigente
    ON public.metricas_zona(celda_lat, celda_lon)
    WHERE fecha_fin_vigencia IS NULL;

-- Índice para consultas de historial por celda
CREATE INDEX IF NOT EXISTS idx_metricas_zona_hist
    ON public.metricas_zona(celda_lat, celda_lon, fecha_inicio_vigencia DESC);

COMMENT ON TABLE public.metricas_zona IS
'Métricas de reportes básicos precalculadas por celda geoespacial de 0.01°×0.01° (~1.1 km). SCD Tipo 2: un registro vigente (fecha_fin_vigencia IS NULL) más historial. Sincronizada diariamente por refrescar_metricas_zona(). La API lee desde mv_metricas_zona (caché plana). Creado: 2026-04-07.';

COMMENT ON COLUMN public.metricas_zona.celda_lat IS 'Latitud del centroide de la celda: ROUND(latitud / 0.01) * 0.01.';
COMMENT ON COLUMN public.metricas_zona.celda_lon IS 'Longitud del centroide de la celda: ROUND(longitud / 0.01) * 0.01.';
COMMENT ON COLUMN public.metricas_zona.tipos_alarma IS 'Distribución de alarmas por tipo. Formato JSONB: [{"tipoalarma_id":N,"cnt":N,"pct":N.N}]. Excluye alarmas falsas.';
COMMENT ON COLUMN public.metricas_zona.cnt_total IS 'Total de alarmas reales en la zona (excluye falsas: calificacion_alarma < 50).';
COMMENT ON COLUMN public.metricas_zona.cnt_falsas IS 'Alarmas en la zona con calificacion_alarma < 50 (falsas alarmas confirmadas).';
COMMENT ON COLUMN public.metricas_zona.avg_minutos_calificacion IS 'Promedio de minutos desde fecha_alarma hasta la primera calificación recibida.';
COMMENT ON COLUMN public.metricas_zona.cnt_capturas IS 'Alarmas en la zona donde flag_hubo_captura = TRUE en alguna descripción.';
COMMENT ON COLUMN public.metricas_zona.cnt_personas_en_zona IS 'Cantidad de usuarios distintos que registraron ubicación en esta celda en las últimas 24h.';
COMMENT ON COLUMN public.metricas_zona.fecha_fin_vigencia IS 'NULL = registro vigente. Fecha = registro histórico cerrado.';
