-- Table: public.personas

-- DROP TABLE IF EXISTS public.personas;

CREATE TABLE IF NOT EXISTS public.personas
(
    persona_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    radio_alarmas_id integer DEFAULT 1,
    login character varying(150) COLLATE pg_catalog."default" NOT NULL,
    user_id_thirdparty character varying(150) COLLATE pg_catalog."default" NOT NULL,
    fechacreacion date,
    marca_bloqueo integer,
    credibilidad_persona numeric(5,2) DEFAULT 100.00,
    fecha_ultima_marca_bloqueo timestamp with time zone,
    tiempo_refresco_mapa integer,
    saldo_poderes integer DEFAULT 0,
    flag_es_policia boolean DEFAULT false,
    numeroplaca character varying(500) COLLATE pg_catalog."default",
    dependenciaasignada character varying(500) COLLATE pg_catalog."default",
    ciudad character varying(500) COLLATE pg_catalog."default",
    pais character varying(500) COLLATE pg_catalog."default",
    flag_es_admin boolean DEFAULT false,
    remitentecambio character varying(500) COLLATE pg_catalog."default",
    fechacorreosolicitud character varying(500) COLLATE pg_catalog."default",
    fechaaplicacionsolicitud timestamp with time zone,
    CONSTRAINT pk_personas PRIMARY KEY (persona_id),
    CONSTRAINT "uk_3Id" UNIQUE (user_id_thirdparty),
    CONSTRAINT uk_login UNIQUE (login)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.personas
    OWNER to w4ll4c3;
-- Index: idx_idpersonas

-- DROP INDEX IF EXISTS public.idx_idpersonas;

CREATE INDEX IF NOT EXISTS idx_idpersonas
    ON public.personas USING btree
    (user_id_thirdparty COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_loginpersonas

-- DROP INDEX IF EXISTS public.idx_loginpersonas;

CREATE INDEX IF NOT EXISTS idx_loginpersonas
    ON public.personas USING btree
    (login COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;