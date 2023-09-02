-- Table: public.tiposubscripcion

-- DROP TABLE IF EXISTS public.tiposubscripcion;

CREATE TABLE IF NOT EXISTS public.tiposubscripcion
(
    tipo_subscr_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    descripcion_tipo character varying(100) COLLATE pg_catalog."default",
    CONSTRAINT pk_tiposubscripcion PRIMARY KEY (tipo_subscr_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.tiposubscripcion
    OWNER to w4ll4c3;