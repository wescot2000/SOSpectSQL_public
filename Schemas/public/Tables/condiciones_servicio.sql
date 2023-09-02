-- Table: public.condiciones_servicio

-- DROP TABLE IF EXISTS public.condiciones_servicio;

CREATE TABLE IF NOT EXISTS public.condiciones_servicio
(
    contrato_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    version_contrato character varying(50) COLLATE pg_catalog."default",
    fecha_inicio_version timestamp with time zone,
    fecha_fin_version timestamp with time zone,
    CONSTRAINT pk_condiciones_servicio PRIMARY KEY (contrato_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.condiciones_servicio
    OWNER to w4ll4c3;