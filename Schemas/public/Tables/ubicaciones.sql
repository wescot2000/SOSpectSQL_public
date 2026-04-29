-- Table: public.ubicaciones

-- DROP TABLE IF EXISTS public.ubicaciones;

CREATE TABLE IF NOT EXISTS public.ubicaciones
(
    ubicacion_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint NOT NULL,
    latitud numeric(9,6),
    longitud numeric(9,6),
    "Tipo" character varying(1) COLLATE pg_catalog."default",
    pais_id character varying(3) COLLATE pg_catalog."default",
    CONSTRAINT pk_ubicaciones PRIMARY KEY (ubicacion_id)
)

TABLESPACE pg_default;

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
-- Index: idx_ubicaciones_geography_tipo_p (PostGIS)
-- Indice espacial GiST para ST_DWithin en vw_cantidad_alarmas_zona (solo ubicaciones tipo P)

-- DROP INDEX IF EXISTS public.idx_ubicaciones_geography_tipo_p;

CREATE INDEX IF NOT EXISTS idx_ubicaciones_geography_tipo_p
    ON public.ubicaciones
    USING GIST (
        (ST_SetSRID(ST_MakePoint(longitud::float8, latitud::float8), 4326)::geography)
    )
    WHERE "Tipo" = 'P';
-- Index: idx_ubicaciones_persona_tipo_p_latest
-- Indice compuesto para busqueda rapida de ultima ubicacion por persona

-- DROP INDEX IF EXISTS public.idx_ubicaciones_persona_tipo_p_latest;

CREATE INDEX IF NOT EXISTS idx_ubicaciones_persona_tipo_p_latest
    ON public.ubicaciones (persona_id, ubicacion_id DESC)
    WHERE "Tipo" = 'P';
    