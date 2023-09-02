-- Table: public.ubicaciones_testing

-- DROP TABLE IF EXISTS public.ubicaciones_testing;

CREATE TABLE IF NOT EXISTS public.ubicaciones_testing
(
    ubicacion_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    persona_id bigint,
    latitud numeric(9,6),
    longitud numeric(9,6),
    fecha_ubicacion timestamp with time zone,
    CONSTRAINT pk_ubicaciones_testing PRIMARY KEY (ubicacion_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.ubicaciones_testing
    OWNER to w4ll4c3;