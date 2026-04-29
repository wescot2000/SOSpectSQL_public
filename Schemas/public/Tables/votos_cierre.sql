-- Table: public.votos_cierre

-- DROP TABLE IF EXISTS public.votos_cierre;

CREATE TABLE IF NOT EXISTS public.votos_cierre
(
    voto_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    solicitud_id bigint NOT NULL,
    persona_id bigint NOT NULL,
    voto boolean NOT NULL,
    fecha_voto timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT votos_cierre_pkey PRIMARY KEY (voto_id),
    CONSTRAINT fk_votos_cierre_solicitud FOREIGN KEY (solicitud_id)
        REFERENCES public.solicitudes_cierre (solicitud_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_votos_cierre_persona FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT uq_votos_cierre_solicitud_persona UNIQUE (solicitud_id, persona_id)
)

TABLESPACE pg_default;


COMMENT ON TABLE public.votos_cierre IS
'Votos de la comunidad sobre solicitudes de cierre de alarmas tipo cierre_encuesta. Un voto por usuario por solicitud. voto=true es a favor del cierre, voto=false es en contra. Agregado: 06-02-2026.';

-- Index: idx_votos_cierre_solicitud (para conteo de votos)

-- DROP INDEX IF EXISTS public.idx_votos_cierre_solicitud;

CREATE INDEX IF NOT EXISTS idx_votos_cierre_solicitud
    ON public.votos_cierre USING btree
    (solicitud_id ASC NULLS LAST)
    TABLESPACE pg_default;
