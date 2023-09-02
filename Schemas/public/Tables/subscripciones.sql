-- Table: public.subscripciones

-- DROP TABLE IF EXISTS public.subscripciones;

CREATE TABLE IF NOT EXISTS public.subscripciones
(
    subscripcion_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    ubicacion_id bigint,
    radio_alarmas_id integer,
    persona_id bigint NOT NULL,
    tipo_subscr_id integer NOT NULL,
    fecha_activacion timestamp with time zone,
    fecha_finalizacion timestamp with time zone,
    poderes_consumidos integer,
    id_rel_protegido bigint,
    cantidad_protegidos_adquirida integer,
    observaciones character varying(500) COLLATE pg_catalog."default",
    CONSTRAINT pk_subscripciones PRIMARY KEY (subscripcion_id),
    CONSTRAINT fk_subscrip_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_subscrip_reference_radio_al FOREIGN KEY (radio_alarmas_id)
        REFERENCES public.radio_alarmas (radio_alarmas_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_subscrip_reference_relprotegidos FOREIGN KEY (id_rel_protegido)
        REFERENCES public.relacion_protegidos (id_rel_protegido) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_subscrip_reference_tiposubscr FOREIGN KEY (tipo_subscr_id)
        REFERENCES public.tiposubscripcion (tipo_subscr_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.subscripciones
    OWNER to w4ll4c3;
-- Index: fki_fk_subscrip_reference_relprotegidos

-- DROP INDEX IF EXISTS public.fki_fk_subscrip_reference_relprotegidos;

CREATE INDEX IF NOT EXISTS fki_fk_subscrip_reference_relprotegidos
    ON public.subscripciones USING btree
    (id_rel_protegido ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_subscripciones_fecha_finalizacion

-- DROP INDEX IF EXISTS public.idx_subscripciones_fecha_finalizacion;

CREATE INDEX IF NOT EXISTS idx_subscripciones_fecha_finalizacion
    ON public.subscripciones USING btree
    (fecha_finalizacion ASC NULLS LAST)
    TABLESPACE pg_default;