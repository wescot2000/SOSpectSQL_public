-- Table: public.fotos_descripciones_alarmas

-- DROP TABLE IF EXISTS public.fotos_descripciones_alarmas;

CREATE TABLE IF NOT EXISTS public.fotos_descripciones_alarmas
(
    foto_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    iddescripcion bigint NOT NULL,
    url_foto character varying(500) COLLATE pg_catalog."default" NOT NULL,
    nombre_archivo_original character varying(200) COLLATE pg_catalog."default",
    tipo_mime character varying(50) COLLATE pg_catalog."default",
    tamano_bytes bigint,
    ancho_pixels integer,
    alto_pixels integer,
    es_video boolean NOT NULL DEFAULT false,
    orden integer,
    fecha_subida timestamp with time zone NOT NULL DEFAULT NOW(),
    bucket_s3 character varying(100) COLLATE pg_catalog."default",
    thumbnail_url character varying(500) COLLATE pg_catalog."default",
    estado character varying(1) COLLATE pg_catalog."default" DEFAULT 'A'::character varying,
    CONSTRAINT pk_fotos_descripciones_alarmas PRIMARY KEY (foto_id),
    CONSTRAINT fk_fotos_reference_descripcionesalarmas FOREIGN KEY (iddescripcion)
        REFERENCES public.descripcionesalarmas (iddescripcion) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE CASCADE
)

TABLESPACE pg_default;


COMMENT ON TABLE public.fotos_descripciones_alarmas
    IS 'Almacena las fotografías y videos adjuntos a las descripciones de alarmas. Los archivos multimedia se almacenan en S3 y aquí solo se guarda la URL y metadata.';

COMMENT ON COLUMN public.fotos_descripciones_alarmas.es_video
    IS 'true=video, false=foto';

COMMENT ON COLUMN public.fotos_descripciones_alarmas.orden
    IS 'Orden de visualización de la foto/video (1-5)';

COMMENT ON COLUMN public.fotos_descripciones_alarmas.estado
    IS 'A=Activa, I=Inactiva, P=Pendiente de procesar';

-- Index: idx_fotos_descripcion

-- DROP INDEX IF EXISTS public.idx_fotos_descripcion;

CREATE INDEX IF NOT EXISTS idx_fotos_descripcion
    ON public.fotos_descripciones_alarmas USING btree
    (iddescripcion ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: idx_fotos_fecha_subida

-- DROP INDEX IF EXISTS public.idx_fotos_fecha_subida;

CREATE INDEX IF NOT EXISTS idx_fotos_fecha_subida
    ON public.fotos_descripciones_alarmas USING btree
    (fecha_subida DESC NULLS LAST)
    TABLESPACE pg_default;

-- Index: idx_fotos_estado

-- DROP INDEX IF EXISTS public.idx_fotos_estado;

CREATE INDEX IF NOT EXISTS idx_fotos_estado
    ON public.fotos_descripciones_alarmas USING btree
    (estado COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

-- Index: idx_fotos_tipo

-- DROP INDEX IF EXISTS public.idx_fotos_tipo;

CREATE INDEX IF NOT EXISTS idx_fotos_tipo
    ON public.fotos_descripciones_alarmas USING btree
    (es_video ASC NULLS LAST)
    TABLESPACE pg_default;
