-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.alarmas_likes
-- Creado: 23-02-2026
-- Propósito: Registro de "Me gusta" de usuarios a alarmas.
-- Un usuario solo puede dar like una vez por alarma (UK constraint).
-- Los likes influyen en el ranking_relevancia del feed Para Ti.

-- DROP TABLE IF EXISTS public.alarmas_likes;

CREATE TABLE IF NOT EXISTS public.alarmas_likes
(
    like_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    alarma_id bigint NOT NULL,
    persona_id bigint NOT NULL,
    fecha_like timestamp with time zone DEFAULT now(),
    CONSTRAINT pk_alarmas_likes PRIMARY KEY (like_id),
    CONSTRAINT uk_alarma_persona_like UNIQUE (alarma_id, persona_id),
    CONSTRAINT fk_alarma_like FOREIGN KEY (alarma_id)
        REFERENCES public.alarmas (alarma_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT fk_persona_like FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;


-- Índice para contar likes por alarma rápidamente
CREATE INDEX IF NOT EXISTS idx_likes_alarma ON public.alarmas_likes(alarma_id);

COMMENT ON TABLE public.alarmas_likes IS
'Registro de Me gusta de usuarios a alarmas. Cada usuario puede dar like una sola vez por alarma. Los likes incrementan el ranking_relevancia en el feed Para Ti.';


