-- TABLE: public.mv_metricas_emprendedores
-- Caché de lectura rápida de métricas de emprendedores para el endpoint de dashboard.
-- Una fila por emprendimiento activo.
--
-- Flujo de actualización:
--   refrescar_metricas_emprendedores() calcula el ranking, lo guarda en
--   metricas_emprendedores (SCD Tipo 2) y luego sincroniza esta tabla con los valores vigentes.
--
-- La API lee desde ESTA tabla:
--   GET /Emprendimientos/ObtenerDashboardEmprendedor
--   → Retorno O(1), sin agregaciones en tiempo real.
--
-- Se refresca con: CALL public.refrescar_metricas_emprendedores()
-- Cron diario a las 22:00 UTC (10 pm Londres):
--   SELECT cron.schedule('ranking-emprendedores', '0 22 * * *',
--     'CALL public.refrescar_metricas_emprendedores()');
--
-- Creado: 2026-04-09
--

CREATE TABLE IF NOT EXISTS public.mv_metricas_emprendedores (
    pais                              VARCHAR(100)  NOT NULL,
    id_emprendimiento                 BIGINT        NOT NULL REFERENCES public.emprendimientos(id_emprendimiento),
    nombre_emprendimiento             VARCHAR(500),

    -- Métricas copiadas de public.emprendimientos
    reputacion_promedio               NUMERIC(3,2),
    total_calificaciones              INTEGER       NOT NULL DEFAULT 0,
    promedio_tiempo_respuesta_minutos INTEGER,
    porcentaje_satisfaccion           NUMERIC(5,2),
    total_chats_mes_actual            INTEGER       NOT NULL DEFAULT 0,
    total_transacciones_exitosas      INTEGER       NOT NULL DEFAULT 0,
    badges_ganados                    JSONB,

    -- Ranking calculado
    puesto_en_pais                    INTEGER,
    total_emprendedores_en_pais       INTEGER       NOT NULL DEFAULT 0,

    -- Auditoría
    fecha_calculo                     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_mv_metricas_emprendedores_pk UNIQUE (pais, id_emprendimiento)
);

-- Índice para lookup por emprendimiento
CREATE INDEX IF NOT EXISTS idx_mv_metricas_emprendedores_emp
    ON public.mv_metricas_emprendedores(pais, id_emprendimiento);

-- Índice para obtener el mejor y el peor de un país rápidamente
CREATE INDEX IF NOT EXISTS idx_mv_metricas_emprendedores_ranking
    ON public.mv_metricas_emprendedores(pais, puesto_en_pais);

COMMENT ON TABLE public.mv_metricas_emprendedores IS
'Caché de lectura rápida de métricas de emprendedores. Una fila por emprendimiento activo. Sincronizada diariamente por refrescar_metricas_emprendedores() desde metricas_emprendedores (SCD Tipo 2). Endpoint: GET /Emprendimientos/ObtenerDashboardEmprendedor. Creado: 2026-04-09.';

COMMENT ON COLUMN public.mv_metricas_emprendedores.total_emprendedores_en_pais IS 'Total de emprendimientos activos en el mismo país. Se precalcula para no requerir COUNT en tiempo real.';
