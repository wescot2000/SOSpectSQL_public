-- Table: migracion.migra_app_versions

-- DROP TABLE IF EXISTS migracion.migra_app_versions;

CREATE TABLE IF NOT EXISTS migracion.migra_app_versions
(
    id integer,
    version_number character varying(10) COLLATE pg_catalog."default",
    is_supported boolean,
    date_added timestamp without time zone
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS migracion.migra_app_versions
    OWNER to w4ll4c3;