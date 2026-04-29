-- Table: public.pol_aprobacion_ciudadana
-- Propósito: Almacena la calificación ciudadana (1-5 estrellas) que cada usuario registra
--            para cada político. Una sola calificación vigente por (politico_id, persona_id);
--            al votar de nuevo se hace UPDATE, no INSERT.
-- Creada: 2026-03-28

-- DROP TABLE IF EXISTS public.pol_aprobacion_ciudadana;

CREATE TABLE IF NOT EXISTS public.pol_aprobacion_ciudadana
(
    aprobacion_id   BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    politico_id     INTEGER         NOT NULL,
    persona_id      BIGINT          NOT NULL,
    calificacion    SMALLINT        NOT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_pol_aprobacion_persona UNIQUE (politico_id, persona_id),
    CONSTRAINT chk_calificacion CHECK (calificacion BETWEEN 1 AND 5),
    CONSTRAINT fk_aprobacion_politico FOREIGN KEY (politico_id)
        REFERENCES public.pol_politicos (politico_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_aprobacion_persona FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

COMMENT ON TABLE public.pol_aprobacion_ciudadana
    IS 'Calificación ciudadana (1-5 estrellas) por usuario por político. Máximo una fila por (politico_id, persona_id); actualizable vía ON CONFLICT DO UPDATE.';

COMMENT ON COLUMN public.pol_aprobacion_ciudadana.calificacion
    IS '1 = Muy malo, 2 = Malo, 3 = Regular, 4 = Bueno, 5 = Excelente';

COMMENT ON COLUMN public.pol_aprobacion_ciudadana.updated_at
    IS 'Fecha de la última modificación de la calificación por este usuario';

-- Index: idx_pol_aprobacion_politico
-- Optimiza las consultas del procedure refrescar_metricas_politico
-- que agrega calificaciones por politico_id.

-- DROP INDEX IF EXISTS public.idx_pol_aprobacion_politico;

CREATE INDEX IF NOT EXISTS idx_pol_aprobacion_politico
    ON public.pol_aprobacion_ciudadana USING btree
    (politico_id ASC NULLS LAST)
    TABLESPACE pg_default;
