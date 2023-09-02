-- Table: public.tiporelacion

-- DROP TABLE IF EXISTS public.tiporelacion;

CREATE TABLE IF NOT EXISTS public.tiporelacion
(
    tiporelacion_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    descripciontiporel character varying(150) COLLATE pg_catalog."default",
    CONSTRAINT pk_tiporelacion PRIMARY KEY (tiporelacion_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.tiporelacion
    OWNER to w4ll4c3;