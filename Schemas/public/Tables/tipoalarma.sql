-- Table: public.tipoalarma

-- DROP TABLE IF EXISTS public.tipoalarma;

CREATE TABLE IF NOT EXISTS public.tipoalarma
(
    tipoalarma_id integer NOT NULL,
    descripciontipoalarma character varying(50) COLLATE pg_catalog."default" NOT NULL,
    icono character varying(50) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT tipoalarma_pkey PRIMARY KEY (tipoalarma_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.tipoalarma
    OWNER to w4ll4c3;