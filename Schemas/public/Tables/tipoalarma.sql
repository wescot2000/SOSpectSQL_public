-- Table: public.tipoalarma

-- DROP TABLE IF EXISTS public.tipoalarma;

CREATE TABLE IF NOT EXISTS public.tipoalarma
(
    tipoalarma_id integer NOT NULL,
    descripciontipoalarma character varying(50) COLLATE pg_catalog."default" NOT NULL,
    icono character varying(50) COLLATE pg_catalog."default" NOT NULL,
    minutos_vigencia integer DEFAULT 90,
    radio_interes_metros integer,
    short_alias character varying(30) COLLATE pg_catalog."default" NOT NULL,
    is_advertising boolean DEFAULT false,
    categoria_alarma_id integer,
    es_indicador_politico boolean NOT NULL DEFAULT false,
    visible_en_app_android boolean NOT NULL DEFAULT true,
    visible_en_app_ios boolean NOT NULL DEFAULT true,
    requiere_mensaje_advertencia_android boolean NOT NULL DEFAULT false,
    requiere_mensaje_advertencia_ios boolean NOT NULL DEFAULT false,
    tipo_cierre character varying(20) COLLATE pg_catalog."default" NOT NULL DEFAULT 'cierre_captura'::character varying,
    color_fondo_feed character varying(9) COLLATE pg_catalog."default",
    CONSTRAINT tipoalarma_pkey PRIMARY KEY (tipoalarma_id),
    CONSTRAINT fk_tipoalarma_categoria FOREIGN KEY (categoria_alarma_id)
        REFERENCES public.categoria_alarma (categoria_alarma_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;


COMMENT ON COLUMN public.tipoalarma.radio_interes_metros
    IS 'Radio personalizado en metros para este tipo de alarma. Si es NULL, usa radio_mts del usuario.';

COMMENT ON COLUMN public.tipoalarma.short_alias
    IS 'Etiqueta corta y amigable para mostrar en UI (filtros, clusters, etc.). Ej: "Crimen", "Advertencia", "Riña"';

COMMENT ON COLUMN public.tipoalarma.is_advertising
    IS 'Indica si este tipo de alarma es una alarma publicitaria (Promoción local). Las alarmas publicitarias tienen reglas especiales de visualización y monetización.';

COMMENT ON COLUMN public.tipoalarma.categoria_alarma_id
    IS 'Relaciona el tipo de alarma con su categoría (SEGURIDAD, POLITICA, INFRAESTRUCTURA, etc.)';

COMMENT ON COLUMN public.tipoalarma.es_indicador_politico
    IS 'Flag que indica si esta alarma se debe considerar para análisis político-territorial. Las alarmas personales (mascota perdida, persona perdida, etc.) NO son indicadores políticos.';

COMMENT ON COLUMN public.tipoalarma.tipo_cierre
    IS 'Define qué pantalla de cierre usar: cierre_captura, cierre_encuesta, cierre_persona, cierre_mascota, cierre_basico, sin_cierre. Agregado: 06-02-2026.';

COMMENT ON COLUMN public.tipoalarma.color_fondo_feed
    IS 'Color de fondo para mostrar en el feed (formato hex: #RRGGBB o #AARRGGBB). Si es NULL, usa gris claro #F5F5F5 por defecto. La red de confianza (flag_red_confianza) siempre override con verde. Agregado: 10-02-2026.';
-- Index: idx_tipoalarma_categoria

-- DROP INDEX IF EXISTS public.idx_tipoalarma_categoria;

CREATE INDEX IF NOT EXISTS idx_tipoalarma_categoria
    ON public.tipoalarma USING btree
    (categoria_alarma_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_tipoalarma_es_indicador_politico

-- DROP INDEX IF EXISTS public.idx_tipoalarma_es_indicador_politico;

CREATE INDEX IF NOT EXISTS idx_tipoalarma_es_indicador_politico
    ON public.tipoalarma USING btree
    (es_indicador_politico ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE es_indicador_politico = true;
-- Index: idx_tipoalarma_is_advertising

-- DROP INDEX IF EXISTS public.idx_tipoalarma_is_advertising;

CREATE INDEX IF NOT EXISTS idx_tipoalarma_is_advertising
    ON public.tipoalarma USING btree
    (is_advertising ASC NULLS LAST)
    TABLESPACE pg_default
    WHERE is_advertising = true;
-- Index: idx_tipoalarma_short_alias

-- DROP INDEX IF EXISTS public.idx_tipoalarma_short_alias;

CREATE INDEX IF NOT EXISTS idx_tipoalarma_short_alias
    ON public.tipoalarma USING btree
    (short_alias COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;