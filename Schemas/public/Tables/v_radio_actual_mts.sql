-- Table: public.v_radio_actual_mts

-- DROP TABLE IF EXISTS public.v_radio_actual_mts;

CREATE TABLE IF NOT EXISTS public.v_radio_actual_mts
(
    radio integer
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.v_radio_actual_mts
    OWNER to w4ll4c3;