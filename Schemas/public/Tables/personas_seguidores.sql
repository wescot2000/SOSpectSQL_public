-- Table: public.personas_seguidores
-- Creado: 23-02-2026
-- Propósito: Relación de seguimiento estilo red social (gratuito, sin notificaciones push).
-- Patrón: igual a Twitter/Instagram/TikTok - tabla separada con índices en ambas columnas.
-- Diferencia con relacion_protegidos: el seguimiento es gratuito, unilateral y no genera notificaciones push.

-- DROP TABLE IF EXISTS public.personas_seguidores;

CREATE TABLE IF NOT EXISTS public.personas_seguidores
(
    seguimiento_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    seguidor_persona_id bigint NOT NULL,
    seguido_persona_id bigint NOT NULL,
    fecha_seguimiento timestamp with time zone DEFAULT now(),
    CONSTRAINT pk_personas_seguidores PRIMARY KEY (seguimiento_id),
    CONSTRAINT uk_seguimiento UNIQUE (seguidor_persona_id, seguido_persona_id),
    CONSTRAINT fk_seguidor FOREIGN KEY (seguidor_persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT fk_seguido FOREIGN KEY (seguido_persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT chk_no_seguirse_a_si_mismo CHECK (seguidor_persona_id <> seguido_persona_id)
)

TABLESPACE pg_default;


-- Índice para consultar "a quiénes sigo" (seguidor → seguidos)
CREATE INDEX IF NOT EXISTS idx_seguidor ON public.personas_seguidores(seguidor_persona_id);

-- Índice para consultar "quiénes me siguen" (seguido → seguidores)
CREATE INDEX IF NOT EXISTS idx_seguido ON public.personas_seguidores(seguido_persona_id);

COMMENT ON TABLE public.personas_seguidores IS
'Relación de seguimiento gratuito estilo red social. Un seguidor ve las alarmas del seguido en la pestaña Siguiendo, sin recibir notificaciones push. Diferente a relacion_protegidos que implica pago y notificaciones.';
