CREATE TABLE IF NOT EXISTS public.paises_convenios
(
    pais_convenio_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    pais_id char(3) NOT NULL,
    descripcion varchar(100),
    iso_alpha_3 char(3),
    iso_numeric char(3),
    flag boolean NOT NULL DEFAULT false,
    fecha_inicio date,
    fecha_fin date,
    iso_alpha_2 char(2),
    CONSTRAINT pk_paises_convenios PRIMARY KEY (pais_convenio_id),
    CONSTRAINT uq_paises_unicos UNIQUE (pais_id, fecha_inicio)
)
TABLESPACE pg_default;

    