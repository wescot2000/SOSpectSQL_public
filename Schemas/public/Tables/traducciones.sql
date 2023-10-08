-- Table: public.traducciones

-- DROP TABLE IF EXISTS public.traducciones;

CREATE TABLE IF NOT EXISTS public.traducciones
(
    traduccion_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    clave character varying(255) COLLATE pg_catalog."default",
    idioma character varying(10) COLLATE pg_catalog."default",
    texto character varying(1000) COLLATE pg_catalog."default",
    CONSTRAINT unique_traducciones UNIQUE (clave, idioma)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.traducciones
    OWNER to w4ll4c3;