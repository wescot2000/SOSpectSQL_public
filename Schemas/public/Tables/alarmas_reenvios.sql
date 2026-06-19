-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.alarmas_reenvios
-- Creado: 23-02-2026
-- Propósito: Registro de reenvíos (Retweet) de alarmas por usuarios.
-- Cuando un usuario reenvía una alarma, esta aparece en la pestaña "Siguiendo" de sus seguidores.
-- Un usuario solo puede reenviar una alarma una vez (UK constraint).

-- DROP TABLE IF EXISTS public.alarmas_reenvios;

CREATE TABLE IF NOT EXISTS public.alarmas_reenvios
(
    reenvio_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    alarma_id bigint NOT NULL,
    persona_id bigint NOT NULL,
    fecha_reenvio timestamp with time zone DEFAULT now(),
    CONSTRAINT pk_alarmas_reenvios PRIMARY KEY (reenvio_id),
    CONSTRAINT uk_alarma_persona_reenvio UNIQUE (alarma_id, persona_id),
    CONSTRAINT fk_alarma_reenvio FOREIGN KEY (alarma_id)
        REFERENCES public.alarmas (alarma_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT fk_persona_reenvio FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)

TABLESPACE pg_default;


-- Índice para contar reenvíos por alarma
CREATE INDEX IF NOT EXISTS idx_reenvios_alarma ON public.alarmas_reenvios(alarma_id);

-- Índice para consultar alarmas reenviadas por un usuario específico
CREATE INDEX IF NOT EXISTS idx_reenvios_persona ON public.alarmas_reenvios(persona_id);

COMMENT ON TABLE public.alarmas_reenvios IS
'Registro de reenvíos (equivalente a Retweet) de alarmas. Cuando un usuario reenvía, la alarma aparece en el feed Siguiendo de sus seguidores. Máximo un reenvío por usuario por alarma.';


