-- Table: public.traducciones_contrato

-- DROP TABLE IF EXISTS public.traducciones_contrato;

CREATE TABLE IF NOT EXISTS public.traducciones_contrato
(
    traduccion_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    contrato_id integer NOT NULL,
    texto_traducido character varying(50000) COLLATE pg_catalog."default",
    idioma character varying(10) COLLATE pg_catalog."default",
    fecha_traduccion timestamp with time zone,
    CONSTRAINT pk_traducciones_contrato PRIMARY KEY (traduccion_id),
    CONSTRAINT fk_traducciones_contrato_reference_condiciones_servicio FOREIGN KEY (contrato_id)
        REFERENCES public.condiciones_servicio (contrato_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.traducciones_contrato
    OWNER to w4ll4c3;