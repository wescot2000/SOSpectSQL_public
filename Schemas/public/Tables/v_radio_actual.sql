-- Table: public.v_radio_actual

-- DROP TABLE IF EXISTS public.v_radio_actual;

CREATE TABLE IF NOT EXISTS public.v_radio_actual
(
    radio integer
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.v_radio_actual
    OWNER to w4ll4c3;