-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.relacion_protegidos

-- DROP TABLE IF EXISTS public.relacion_protegidos;

CREATE TABLE IF NOT EXISTS public.relacion_protegidos
(
    id_rel_protegido bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    tiporelacion_id integer,
    id_persona_protector bigint NOT NULL,
    id_persona_protegida bigint NOT NULL,
    poderes_consumidos integer,
    fecha_activacion timestamp with time zone,
    fecha_finalizacion timestamp with time zone,
    fecha_suspension timestamp with time zone,
    fecha_reactivacion timestamp with time zone,
    CONSTRAINT pk_relacion_protegidos PRIMARY KEY (id_rel_protegido),
    CONSTRAINT fk_relacion_reference_personasprotector FOREIGN KEY (id_persona_protector)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_relacion_reference_personasprotegida FOREIGN KEY (id_persona_protegida)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_relacion_reference_tiporela FOREIGN KEY (tiporelacion_id)
        REFERENCES public.tiporelacion (tiporelacion_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

-- Index: idx_relacion_protegidos_fecha_finalizacion

-- DROP INDEX IF EXISTS public.idx_relacion_protegidos_fecha_finalizacion;

CREATE INDEX IF NOT EXISTS idx_relacion_protegidos_fecha_finalizacion
    ON public.relacion_protegidos USING btree
    (fecha_finalizacion ASC NULLS LAST)
    TABLESPACE pg_default;

