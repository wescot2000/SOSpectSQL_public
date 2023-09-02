-- Table: public.app_versions

-- DROP TABLE IF EXISTS public.app_versions;

CREATE TABLE IF NOT EXISTS public.app_versions
(
    id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    version_number character varying(10) COLLATE pg_catalog."default",
    is_supported boolean,
    date_added timestamp without time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
    CONSTRAINT pk_app_versions PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.app_versions
    OWNER to w4ll4c3;