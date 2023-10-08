-- Table: public.atencion_policiaca

-- DROP TABLE IF EXISTS public.atencion_policiaca;

CREATE TABLE IF NOT EXISTS public.atencion_policiaca
(
    atencion_policiaca_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    alarma_id bigint NOT NULL,
    persona_id bigint NOT NULL,
    fecha_autoasignacion timestamp with time zone,
    CONSTRAINT pk_atencion_policiaca_id PRIMARY KEY (atencion_policiaca_id),
    CONSTRAINT fk_atencion_policiaca_id_reference_alarmas FOREIGN KEY (alarma_id)
        REFERENCES public.alarmas (alarma_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_atencion_policiaca_id_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.atencion_policiaca
    OWNER to w4ll4c3;