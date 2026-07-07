-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.app_versions

-- DROP TABLE IF EXISTS public.app_versions;

CREATE TABLE IF NOT EXISTS public.app_versions
(
    id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    version_number character varying(10) COLLATE pg_catalog."default",
    is_supported boolean,
    date_added timestamp without time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
    plataforma character varying(20) COLLATE pg_catalog."default",
    CONSTRAINT pk_app_versions PRIMARY KEY (id)
)

TABLESPACE pg_default;

-- plataforma = NULL significa "aplica a todas las plataformas" (regla generica).
-- El indice unico considera NULL como un valor mas (via COALESCE) para permitir
-- una fila generica por version_number y, ademas, una fila especifica por
-- plataforma (Android, iOS, y a futuro canales como Huawei/Xiaomi) sin duplicarse.
CREATE UNIQUE INDEX IF NOT EXISTS uk_ver_plataforma
    ON public.app_versions (version_number, COALESCE(plataforma, ''));


