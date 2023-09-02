-- Table: public.dispositivos

-- DROP TABLE IF EXISTS public.dispositivos;

CREATE TABLE IF NOT EXISTS public.dispositivos
(
    id_dispositivo bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint NOT NULL,
    registrationid character varying(200) COLLATE pg_catalog."default" NOT NULL,
    plataforma character varying(100) COLLATE pg_catalog."default",
    idioma character varying(10) COLLATE pg_catalog."default" NOT NULL,
    fecha_inicio timestamp with time zone,
    fecha_fin timestamp with time zone,
    CONSTRAINT pk_dispositivos PRIMARY KEY (id_dispositivo),
    CONSTRAINT fk_dispositivos_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.dispositivos
    OWNER to w4ll4c3;