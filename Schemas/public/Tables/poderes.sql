-- Table: public.poderes

-- DROP TABLE IF EXISTS public.poderes;

CREATE TABLE IF NOT EXISTS public.poderes
(
    poder_id integer NOT NULL,
    cantidad integer,
    valor_cop integer,
    valor_usd numeric(5,2),
    fecha_inicio timestamp with time zone,
    fecha_fin timestamp with time zone,
    "ProductId" character varying(200) COLLATE pg_catalog."default",
    CONSTRAINT pk_poderes PRIMARY KEY (poder_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.poderes
    OWNER to w4ll4c3;