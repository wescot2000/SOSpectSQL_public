-- Table: public.solicitudes_cierre

-- DROP TABLE IF EXISTS public.solicitudes_cierre;

CREATE TABLE IF NOT EXISTS public.solicitudes_cierre
(
    solicitud_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    alarma_id bigint NOT NULL,
    persona_id bigint NOT NULL,
    descripcion character varying(500) COLLATE pg_catalog."default",
    fecha_solicitud timestamp with time zone NOT NULL DEFAULT now(),
    fecha_limite_votacion timestamp with time zone NOT NULL,
    estado character varying(20) COLLATE pg_catalog."default" DEFAULT 'activa'::character varying,
    votos_si integer NOT NULL DEFAULT 0,
    votos_no integer NOT NULL DEFAULT 0,
    CONSTRAINT solicitudes_cierre_pkey PRIMARY KEY (solicitud_id),
    CONSTRAINT fk_solicitudes_cierre_alarma FOREIGN KEY (alarma_id)
        REFERENCES public.alarmas (alarma_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_solicitudes_cierre_persona FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    iddescripcion_propuesta bigint,
    CONSTRAINT chk_solicitudes_cierre_estado CHECK (estado IN ('activa', 'aprobada', 'denegada')),
    CONSTRAINT fk_solicitudes_cierre_descripcion FOREIGN KEY (iddescripcion_propuesta)
        REFERENCES public.descripcionesalarmas (iddescripcion) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE SET NULL
)

TABLESPACE pg_default;


COMMENT ON TABLE public.solicitudes_cierre IS
'Solicitudes de cierre comunitario para alarmas tipo cierre_encuesta (Alerta Ciudadana). Cualquier usuario puede proponer el cierre, la comunidad vota en 24h. Agregado: 06-02-2026.';

COMMENT ON COLUMN public.solicitudes_cierre.estado IS
'Estado de la solicitud: activa (en votación), aprobada (mayoría a favor o sin votos), denegada (mayoría en contra).';

COMMENT ON COLUMN public.solicitudes_cierre.fecha_limite_votacion IS
'Fecha límite para votar. Calculado como fecha_solicitud + 24 horas. Después de esta fecha, ProcesarSolicitudesCierreVencidas evalúa el resultado.';

COMMENT ON COLUMN public.solicitudes_cierre.iddescripcion_propuesta IS
'ID de la descripción que contiene las fotos de la propuesta de cierre. Se enlaza desde ProponerCierre en la API. Agregado: 2026-04.';

-- Index: idx_solicitudes_cierre_alarma_activa (índice único parcial - 1 solicitud activa por alarma)

-- DROP INDEX IF EXISTS public.idx_solicitudes_cierre_alarma_activa;

CREATE UNIQUE INDEX IF NOT EXISTS idx_solicitudes_cierre_alarma_activa
    ON public.solicitudes_cierre USING btree
    (alarma_id ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE estado = 'activa'::text;

-- Index: idx_solicitudes_cierre_estado_fecha (para ProcesarSolicitudesCierreVencidas)

-- DROP INDEX IF EXISTS public.idx_solicitudes_cierre_estado_fecha;

CREATE INDEX IF NOT EXISTS idx_solicitudes_cierre_estado_fecha
    ON public.solicitudes_cierre USING btree
    (estado COLLATE pg_catalog."default" ASC NULLS LAST, fecha_limite_votacion ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE estado = 'activa'::text;
