-- Table: public.alarmas
-- MODIFICADO: 2026-02-26 - Agregar contadores denormalizados de interacciones sociales

-- DROP TABLE IF EXISTS public.alarmas;

CREATE TABLE IF NOT EXISTS public.alarmas
(
    alarma_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint NOT NULL,
    tipoalarma_id integer NOT NULL,
    fecha_alarma timestamp with time zone NOT NULL,
    latitud numeric(9,6) NOT NULL,
    longitud numeric(9,6) NOT NULL,
    calificacion_alarma numeric(5,2),
    estado_alarma character varying(1) COLLATE pg_catalog."default",
    latitud_originador numeric(9,6),
    longitud_originador numeric(9,6),
    ip_usuario_originador character varying(50) COLLATE pg_catalog."default",
    distancia_alarma_originador numeric(9,2),
    alarma_id_padre bigint,
    evaluada boolean NOT NULL DEFAULT false,
    -- Contadores denormalizados para evitar COUNT en cada consulta del feed
    cnt_likes integer NOT NULL DEFAULT 0,
    cnt_reenvios integer NOT NULL DEFAULT 0,
    cnt_verdaderos integer NOT NULL DEFAULT 0,
    cnt_falsos integer NOT NULL DEFAULT 0,
    CONSTRAINT pk_alarmas PRIMARY KEY (alarma_id),
    CONSTRAINT fk_alarmas_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

-- Index: idx_alarmas_estado_tipo

-- DROP INDEX IF EXISTS public.idx_alarmas_estado_tipo;

CREATE INDEX IF NOT EXISTS idx_alarmas_estado_tipo
    ON public.alarmas USING btree
    (estado_alarma COLLATE pg_catalog."default" ASC NULLS LAST, tipoalarma_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_alarmas_padre_fecha

-- DROP INDEX IF EXISTS public.idx_alarmas_padre_fecha;

CREATE INDEX IF NOT EXISTS idx_alarmas_padre_fecha
    ON public.alarmas USING btree
    (alarma_id_padre ASC NULLS LAST, fecha_alarma ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_alarmas_geography (PostGIS)
-- Indice espacial GiST para ST_DWithin en vw_cantidad_alarmas_zona

-- DROP INDEX IF EXISTS public.idx_alarmas_geography;

CREATE INDEX IF NOT EXISTS idx_alarmas_geography
    ON public.alarmas
    USING GIST (
        (ST_SetSRID(ST_MakePoint(longitud::float8, latitud::float8), 4326)::geography)
    );