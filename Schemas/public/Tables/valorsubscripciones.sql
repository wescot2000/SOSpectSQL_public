-- Table: public.valorsubscripciones

-- DROP TABLE IF EXISTS public.valorsubscripciones;

CREATE TABLE IF NOT EXISTS public.valorsubscripciones
(
    valorsubscripcion_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    tipo_subscr_id integer NOT NULL,
    cantidad_subscripcion integer,
    cantidad_poderes integer NOT NULL,
    tiempo_subscripcion_horas integer,
    CONSTRAINT pk_valorsubscripciones PRIMARY KEY (valorsubscripcion_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.valorsubscripciones
    OWNER to w4ll4c3;