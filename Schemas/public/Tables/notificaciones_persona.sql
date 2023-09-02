-- Table: public.notificaciones_persona

-- DROP TABLE IF EXISTS public.notificaciones_persona;

CREATE TABLE IF NOT EXISTS public.notificaciones_persona
(
    notificacion_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint NOT NULL,
    alarma_id bigint NOT NULL,
    flag_enviado boolean,
    fecha_notificacion timestamp with time zone,
    CONSTRAINT pk_notificaciones_persona PRIMARY KEY (notificacion_id),
    CONSTRAINT fk_notificaciones_persona_reference_alarmas FOREIGN KEY (alarma_id)
        REFERENCES public.alarmas (alarma_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_pnotificaciones_persona_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.notificaciones_persona
    OWNER to w4ll4c3;
-- Index: fki_notificaciones_persona_alarma_id

-- DROP INDEX IF EXISTS public.fki_notificaciones_persona_alarma_id;

CREATE INDEX IF NOT EXISTS fki_notificaciones_persona_alarma_id
    ON public.notificaciones_persona USING btree
    (alarma_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: fki_notificaciones_persona_persona_id

-- DROP INDEX IF EXISTS public.fki_notificaciones_persona_persona_id;

CREATE INDEX IF NOT EXISTS fki_notificaciones_persona_persona_id
    ON public.notificaciones_persona USING btree
    (persona_id ASC NULLS LAST)
    TABLESPACE pg_default;