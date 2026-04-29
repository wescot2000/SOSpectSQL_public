-- TABLE: public.metricas_emprendedores
-- Métricas de emprendedores precalculadas con ranking por país.
-- Diseño SCD Tipo 2: cada ejecución diaria cierra el registro vigente e inserta uno nuevo,
-- preservando el historial completo de evolución de los KPIs por emprendimiento.
--
-- El registro vigente de cada emprendimiento es el que tiene fecha_fin_vigencia IS NULL.
--
-- Esta tabla es interna; la API NO la consulta directamente. El procedure
-- refrescar_metricas_emprendedores() la mantiene y sincroniza los resultados hacia
-- la tabla de caché public.mv_metricas_emprendedores (leída por la API).
--
-- Creado: 2026-04-09
--

CREATE TABLE IF NOT EXISTS public.metricas_emprendedores (
    id                                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Identificador del emprendimiento y su país
    pais                              VARCHAR(100)  NOT NULL,
    id_emprendimiento                 BIGINT        NOT NULL REFERENCES public.emprendimientos(id_emprendimiento),
    nombre_emprendimiento             VARCHAR(500),

    -- Métricas copiadas de public.emprendimientos en el momento del cálculo
    reputacion_promedio               NUMERIC(3,2),
    total_calificaciones              INTEGER       NOT NULL DEFAULT 0,
    promedio_tiempo_respuesta_minutos INTEGER,
    porcentaje_satisfaccion           NUMERIC(5,2),
    total_chats_mes_actual            INTEGER       NOT NULL DEFAULT 0,
    total_transacciones_exitosas      INTEGER       NOT NULL DEFAULT 0,
    badges_ganados                    JSONB,

    -- Ranking calculado en el momento del cálculo
    puesto_en_pais                    INTEGER,

    -- Control SCD Tipo 2
    fecha_inicio_vigencia             TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    fecha_fin_vigencia                TIMESTAMPTZ,   -- NULL = registro vigente

    -- Auditoría
    fecha_calculo                     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- Índice único parcial: garantiza un solo registro vigente por emprendimiento
CREATE UNIQUE INDEX IF NOT EXISTS idx_metricas_emprendedores_vigente
    ON public.metricas_emprendedores(pais, id_emprendimiento)
    WHERE fecha_fin_vigencia IS NULL;

-- Índice para consultas de historial por emprendimiento
CREATE INDEX IF NOT EXISTS idx_metricas_emprendedores_hist
    ON public.metricas_emprendedores(pais, id_emprendimiento, fecha_inicio_vigencia DESC);

COMMENT ON TABLE public.metricas_emprendedores IS
'Métricas de emprendedores precalculadas con ranking por país. SCD Tipo 2: un registro vigente (fecha_fin_vigencia IS NULL) más historial. Sincronizada diariamente por refrescar_metricas_emprendedores(). La API lee desde mv_metricas_emprendedores (caché plana). Creado: 2026-04-09.';

COMMENT ON COLUMN public.metricas_emprendedores.pais IS 'País del propietario del emprendimiento, tomado de public.personas.pais.';
COMMENT ON COLUMN public.metricas_emprendedores.puesto_en_pais IS 'Posición en el ranking nacional. 1 = mejor reputación en el país. Calculado con RANK() OVER (PARTITION BY pais ORDER BY reputacion_promedio DESC, total_calificaciones DESC).';
COMMENT ON COLUMN public.metricas_emprendedores.fecha_fin_vigencia IS 'NULL = registro vigente. Fecha = registro histórico cerrado.';
COMMENT ON COLUMN public.metricas_emprendedores.badges_ganados IS 'Copia del JSONB de badges del emprendimiento en el momento del cálculo.';
