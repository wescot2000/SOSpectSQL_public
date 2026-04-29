-- Table: public.pol_metricas_territorio
-- Módulo político: contadores pre-agregados de alarmas por territorio y período.
-- Evita calcular en tiempo real cruzando PostgreSQL + S3 (datos migrados > 120 días).
-- Actualizada periódicamente por el procedure calcular_metricas_politicos().
--
-- Para nivel REGION/CIUDAD/DISTRITO: usa territorio_id, pais_id = NULL.
-- Para nivel PAIS (Presidente): usa pais_id, territorio_id = NULL.
--
-- Períodos disponibles:
--   24H → últimas 24 horas (evita problemas de timezone que tendría "HOY")
--   7D  → últimos 7 días
--   30D → últimos 30 días

CREATE TABLE IF NOT EXISTS public.pol_metricas_territorio
(
    metrica_id              INTEGER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    territorio_id           INTEGER
                            REFERENCES public.pol_territorios(territorio_id) ON DELETE CASCADE,
    -- NULL cuando la métrica es a nivel PAIS
    pais_id                 CHAR(2)
                            REFERENCES public.paises(pais_id) ON DELETE CASCADE,
    -- NULL cuando la métrica es a nivel REGION/CIUDAD/DISTRITO
    periodo                 VARCHAR(5)      NOT NULL,
    -- '24H', '7D', '30D'
    cnt_alarmas             INTEGER         NOT NULL DEFAULT 0,
    -- Total de alarmas en el período (todos los tipos)
    cnt_alarmas_politico    INTEGER         NOT NULL DEFAULT 0,
    -- Alarmas con tipoalarma.es_indicador_politico = true
    fecha_calculo           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    -- Momento del último recálculo

    CONSTRAINT chk_pol_metricas_periodo
        CHECK (periodo IN ('24H', '7D', '30D')),

    CONSTRAINT chk_pol_metricas_territorio_o_pais
        CHECK (
            (territorio_id IS NOT NULL AND pais_id IS NULL)
         OR (territorio_id IS NULL AND pais_id IS NOT NULL)
        )
)

TABLESPACE pg_default;

COMMENT ON TABLE public.pol_metricas_territorio IS
'Contadores pre-agregados de alarmas por territorio y período (24H, 7D, 30D). Actualizada por calcular_metricas_politicos(). No requiere consultar S3 ni calcular en tiempo real. Solo cubre datos en PostgreSQL (< 120 días).';

COMMENT ON COLUMN public.pol_metricas_territorio.cnt_alarmas IS
'Total de alarmas en el período, todos los tipos (incluye publicidad, mascotas, etc.).';

COMMENT ON COLUMN public.pol_metricas_territorio.cnt_alarmas_politico IS
'Alarmas con tipoalarma.es_indicador_politico=true. Estas son las que impactan en la gestión política (crimen, riña, disturbios, etc.).';

COMMENT ON COLUMN public.pol_metricas_territorio.periodo IS
'Ventana temporal: 24H=últimas 24 horas, 7D=últimos 7 días, 30D=últimos 30 días. Se usa 24H en vez de HOY para evitar inconsistencias de timezone.';

CREATE INDEX IF NOT EXISTS idx_pol_metricas_territorio
    ON public.pol_metricas_territorio(territorio_id)
    WHERE territorio_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_pol_metricas_pais
    ON public.pol_metricas_territorio(pais_id)
    WHERE pais_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_pol_metricas_periodo
    ON public.pol_metricas_territorio(periodo);
