-- TABLE: public.metricas_politico
-- Fuente de verdad de métricas de desempeño por político.
-- Diseño SCD Tipo 2 (Slowly Changing Dimension): cada ejecución diaria del cron
-- cierra el registro anterior (fecha_fin_vigencia = NOW()) e inserta uno nuevo,
-- preservando el historial completo de la evolución de los KPIs.
--
-- El registro vigente de cada político es el que tiene fecha_fin_vigencia IS NULL.
--
-- Esta tabla es interna; la API NO la consulta directamente. El procedure
-- refrescar_metricas_politico() la mantiene y sincroniza los resultados hacia
-- la tabla de caché public.mv_metricas_politico (leída por la API).
--
-- Creado: 2026-03-10
--

CREATE TABLE IF NOT EXISTS public.metricas_politico (
    id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    politico_id           INTEGER      NOT NULL,

    -- Rango de fechas de alarmas consideradas en el cálculo ACUMULADO hasta este registro.
    -- fecha_desde_alarmas: la fecha_alarma más antigua procesada alguna vez para este político.
    -- fecha_hasta_alarmas: NOW() en el momento del cálculo (usado como corte en el próximo delta).
    fecha_desde_alarmas   TIMESTAMPTZ  NOT NULL,
    fecha_hasta_alarmas   TIMESTAMPTZ  NOT NULL,

    -- KPIs acumulados
    cnt_total             INTEGER      NOT NULL DEFAULT 0,    -- total alarmas distintas del político
    cnt_abiertas          INTEGER      NOT NULL DEFAULT 0,    -- alarmas con estado_alarma IS NULL (recalculado cada vez)
    cnt_cerradas          INTEGER      NOT NULL DEFAULT 0,    -- alarmas con estado_alarma = 'C' (acumulado)
    pct_resolucion        NUMERIC(5,1),                       -- (cnt_cerradas * 100.0) / cnt_total; NULL si cnt_total = 0
    cnt_likes             INTEGER      NOT NULL DEFAULT 0,    -- suma acumulada de cnt_likes
    cnt_reenvios          INTEGER      NOT NULL DEFAULT 0,    -- suma acumulada de cnt_reenvios
    avg_dias_resolucion   NUMERIC(8,1),                       -- promedio ponderado de días hasta cierre; NULL si no hay cierres con fecha

    -- Peso para el promedio ponderado de avg_dias_resolucion en el siguiente ciclo.
    -- Se incrementa con cada nueva alarma cerrada que tenga flag_es_cierre_alarma = TRUE
    -- en descripcionesalarmas o migracion.migra_DescripcionesAlarmas.
    cnt_cierres_con_fecha INTEGER      NOT NULL DEFAULT 0,

    -- Distribución por tipo de alarma (JSONB para evitar tabla auxiliar en el historial).
    -- Formato: [{"tipoalarma_id": 1, "cnt": 42, "pct": 55.3}, ...]
    -- La tabla mv_metricas_politico_tipos se usa como caché de lectura para la API.
    tipos_alarma          JSONB,

    -- Vigencia del registro (SCD Tipo 2).
    -- El registro VIGENTE tiene fecha_fin_vigencia IS NULL.
    -- Al ejecutar el cron: se cierra el vigente y se inserta uno nuevo.
    fecha_inicio_vigencia TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    fecha_fin_vigencia    TIMESTAMPTZ,

    -- Score de gestión ponderado (0–100). Combina pct_resolucion excluyendo falsas alarmas,
    -- penalización por alarmas abiertas (días × viralidad, máx -40 pts) y
    -- premio por cierres (viralidad del cierre, máx +10 pts).
    score_gestion         NUMERIC(5,1),

    -- Auditoría
    fecha_calculo         TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Índice único parcial: garantiza un solo registro vigente por político.
-- Requerido para el ON CONFLICT en las sincronizaciones.
CREATE UNIQUE INDEX IF NOT EXISTS idx_metricas_politico_vigente
    ON public.metricas_politico(politico_id)
    WHERE fecha_fin_vigencia IS NULL;

-- Índice para consultas de historial por político.
CREATE INDEX IF NOT EXISTS idx_metricas_politico_hist
    ON public.metricas_politico(politico_id, fecha_inicio_vigencia DESC);

COMMENT ON TABLE public.metricas_politico IS
'Fuente de verdad de métricas de desempeño por político. SCD Tipo 2: un registro vigente (fecha_fin_vigencia IS NULL) más el historial de versiones anteriores. El procedure refrescar_metricas_politico() actualiza esta tabla diariamente de forma incremental (solo procesa alarmas nuevas desde fecha_hasta_alarmas) consultando public.alarmas UNION migracion.migra_alarmas. No es consultada directamente por la API; sus resultados vigentes se sincronizan hacia mv_metricas_politico. Creado: 2026-03-10.';

COMMENT ON COLUMN public.metricas_politico.fecha_desde_alarmas IS 'Fecha más antigua de alarma procesada alguna vez para este político (no cambia tras la carga inicial).';
COMMENT ON COLUMN public.metricas_politico.fecha_hasta_alarmas IS 'NOW() en el momento del cálculo. En el siguiente ciclo se procesan solo alarmas con fecha_alarma > este valor.';
COMMENT ON COLUMN public.metricas_politico.cnt_cierres_con_fecha IS 'Número de cierres con fecha conocida (flag_es_cierre_alarma=TRUE). Usado como peso para el promedio ponderado de avg_dias_resolucion en ciclos futuros.';
COMMENT ON COLUMN public.metricas_politico.tipos_alarma IS 'Distribución de alarmas por tipo. Formato JSONB: [{"tipoalarma_id":N,"cnt":N,"pct":N.N}]. Espejo en mv_metricas_politico_tipos para lectura rápida de la API.';
COMMENT ON COLUMN public.metricas_politico.fecha_fin_vigencia IS 'NULL = registro actualmente vigente. Fecha = registro histórico cerrado en esa fecha.';
