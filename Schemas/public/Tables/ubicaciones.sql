-- Table: public.ubicaciones

-- DROP TABLE IF EXISTS public.ubicaciones;

CREATE TABLE IF NOT EXISTS public.ubicaciones
(
    ubicacion_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint NOT NULL,
    latitud numeric(9,6),
    longitud numeric(9,6),
    "Tipo" character varying(1) COLLATE pg_catalog."default",
    CONSTRAINT pk_ubicaciones PRIMARY KEY (ubicacion_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.ubicaciones
    OWNER to w4ll4c3;
-- Index: idxPersonaUb

-- DROP INDEX IF EXISTS public."idxPersonaUb";

CREATE INDEX IF NOT EXISTS "idxPersonaUb"
    ON public.ubicaciones USING btree
    (persona_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idxlntd

-- DROP INDEX IF EXISTS public.idxlntd;

CREATE INDEX IF NOT EXISTS idxlntd
    ON public.ubicaciones USING btree
    (longitud ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idxltd

-- DROP INDEX IF EXISTS public.idxltd;

CREATE INDEX IF NOT EXISTS idxltd
    ON public.ubicaciones USING btree
    (latitud ASC NULLS LAST)
    TABLESPACE pg_default;