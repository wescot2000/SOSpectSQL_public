-- Table: public.v_tiempo_subscripcion_dias

-- DROP TABLE IF EXISTS public.v_tiempo_subscripcion_dias;

CREATE TABLE IF NOT EXISTS public.v_tiempo_subscripcion_dias
(
    tiempo_subscripcion_horas integer
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.v_tiempo_subscripcion_dias
    OWNER to w4ll4c3;