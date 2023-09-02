-- Table: public.v_multiplicador

-- DROP TABLE IF EXISTS public.v_multiplicador;

CREATE TABLE IF NOT EXISTS public.v_multiplicador
(
    radio_alarmas_id integer,
    radio_mts integer
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.v_multiplicador
    OWNER to w4ll4c3;