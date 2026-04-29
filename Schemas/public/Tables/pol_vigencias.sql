-- Table: public.pol_vigencias
-- Módulo político: relaciona político × cargo × territorio × período de mandato.
-- Una fila por mandato. El mismo político puede tener registros históricos.
--
-- Para Presidente (cargo_id=1): usa pais_id (no territorio_id).
-- Para Gobernador/Alcalde/Edil (cargo_id!=1): usa territorio_id (no pais_id).
--
-- fecha_fin NULL = mandato actualmente vigente.
-- El índice parcial uq_vigencia_activa_* garantiza que no puede haber
-- dos autoridades vigentes para el mismo cargo+territorio en un momento dado.

CREATE TABLE IF NOT EXISTS public.pol_vigencias
(
    vigencia_id     INTEGER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    politico_id     INTEGER         NOT NULL
                    REFERENCES public.pol_politicos(politico_id) ON DELETE CASCADE,
    cargo_id        SMALLINT        NOT NULL
                    REFERENCES public.pol_cargos(cargo_id) ON DELETE RESTRICT,
    territorio_id   INTEGER
                    REFERENCES public.pol_territorios(territorio_id) ON DELETE RESTRICT,
    -- Poblado para cargo_id IN (2,3,4): Gobernador, Alcalde, Edil
    pais_id         CHAR(2)
                    REFERENCES public.paises(pais_id) ON DELETE RESTRICT,
    -- Poblado solo para cargo_id = 1 (Presidente)
    fecha_inicio    DATE            NOT NULL,
    fecha_fin       DATE,
    -- NULL = mandato vigente actualmente
    activo          BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

    CONSTRAINT chk_pol_vigencias_territorio
        CHECK (
            (cargo_id = 1
             AND pais_id IS NOT NULL
             AND territorio_id IS NULL)
         OR (cargo_id != 1
             AND territorio_id IS NOT NULL
             AND pais_id IS NULL)
        ),

    CONSTRAINT chk_pol_vigencias_fechas
        CHECK (fecha_fin IS NULL OR fecha_fin > fecha_inicio)
)

TABLESPACE pg_default;

COMMENT ON TABLE public.pol_vigencias IS
'Mandatos vigentes e históricos: político × cargo × territorio × fechas. Para Presidente usa pais_id. Para Gobernador/Alcalde/Edil usa territorio_id de pol_territorios. fecha_fin NULL = mandato actual.';

COMMENT ON COLUMN public.pol_vigencias.fecha_fin IS
'NULL indica mandato actualmente vigente. Al ganar las siguientes elecciones se actualiza este campo y se inserta un nuevo registro con el ganador.';

COMMENT ON COLUMN public.pol_vigencias.territorio_id IS
'FK a pol_territorios. REGION para Gobernador, CIUDAD para Alcalde, DISTRITO para Edil. NULL si cargo_id=1 (Presidente usa pais_id).';

COMMENT ON COLUMN public.pol_vigencias.pais_id IS
'FK a paises. Solo para cargo_id=1 (Presidente). NULL para todos los demás cargos.';

CREATE INDEX IF NOT EXISTS idx_pol_vigencias_politico
    ON public.pol_vigencias(politico_id);

CREATE INDEX IF NOT EXISTS idx_pol_vigencias_cargo_territorio
    ON public.pol_vigencias(cargo_id, territorio_id)
    WHERE territorio_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_pol_vigencias_cargo_pais
    ON public.pol_vigencias(cargo_id, pais_id)
    WHERE pais_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_pol_vigencias_fechas
    ON public.pol_vigencias(activo, fecha_inicio, fecha_fin);

-- Garantiza que no puede haber dos autoridades vigentes para el mismo cargo+territorio
-- (fecha_fin IS NULL = mandato vigente)
CREATE UNIQUE INDEX IF NOT EXISTS uq_vigencia_activa_territorio
    ON public.pol_vigencias(cargo_id, territorio_id)
    WHERE fecha_fin IS NULL AND territorio_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_vigencia_activa_pais
    ON public.pol_vigencias(cargo_id, pais_id)
    WHERE fecha_fin IS NULL AND pais_id IS NOT NULL;
