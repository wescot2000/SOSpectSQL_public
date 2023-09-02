-- Table: public.transacciones_personas

-- DROP TABLE IF EXISTS public.transacciones_personas;

CREATE TABLE IF NOT EXISTS public.transacciones_personas
(
    transaccion_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint NOT NULL,
    poder_id integer,
    fecha_transaccion timestamp with time zone,
    ip_transaccion character varying(150) COLLATE pg_catalog."default" NOT NULL,
    tipo_transaccion character varying(50) COLLATE pg_catalog."default",
    purchase_token character varying(5000) COLLATE pg_catalog."default",
    CONSTRAINT pk_transacciones_personas PRIMARY KEY (transaccion_id),
    CONSTRAINT fk_transacciones_personas_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.transacciones_personas
    OWNER to w4ll4c3;