-- FUNCTION: public.calcular_costo_publicidad(integer, integer, integer, boolean, boolean, boolean, integer)

-- DROP FUNCTION IF EXISTS public.calcular_costo_publicidad(integer, integer, integer, boolean, boolean, boolean, integer);

CREATE OR REPLACE FUNCTION public.calcular_costo_publicidad(
    p_radio_metros integer,
    p_duracion_dias integer,
    p_cantidad_media integer,
    p_logo_habilitado boolean,
    p_contacto_habilitado boolean,
    p_domicilio_habilitado boolean,
    p_usuarios_push integer)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    v_costo_base INTEGER := 40;
    v_costo_radio INTEGER := 0;
    v_costo_duracion INTEGER := 0;
    v_costo_media INTEGER := 0;
    v_costo_logo INTEGER := 0;
    v_costo_contacto INTEGER := 0;
    v_costo_domicilio INTEGER := 0;
    v_costo_push INTEGER := 0;
    v_costo_total INTEGER;
BEGIN
    -- Calcular costo de radio extra (base 100m, +20 por cada 500m adicionales)
    IF p_radio_metros > 100 THEN
        v_costo_radio := CEIL((p_radio_metros - 100)::NUMERIC / 500) * 20;
    END IF;

    -- Calcular costo de duración extra (base 1 día, +10 por cada día adicional)
    IF p_duracion_dias > 1 THEN
        v_costo_duracion := (p_duracion_dias - 1) * 10;
    END IF;

    -- Calcular costo de media extra (base 1 item, +20 por cada item adicional)
    IF p_cantidad_media > 1 THEN
        v_costo_media := (p_cantidad_media - 1) * 20;
    END IF;

    -- Calcular costo de logo
    IF p_logo_habilitado THEN
        v_costo_logo := 10;
    END IF;

    -- Calcular costo de contacto
    IF p_contacto_habilitado THEN
        v_costo_contacto := 5;
    END IF;

    -- Calcular costo de domicilio
    IF p_domicilio_habilitado THEN
        v_costo_domicilio := 5;
    END IF;

    -- Calcular costo de push (20 poderes por cada 50 usuarios)
    IF p_usuarios_push > 0 THEN
        v_costo_push := CEIL(p_usuarios_push::NUMERIC / 50) * 20;
    END IF;

    -- Calcular costo total
    v_costo_total := v_costo_base + v_costo_radio + v_costo_duracion + v_costo_media +
                     v_costo_logo + v_costo_contacto + v_costo_domicilio + v_costo_push;

    RETURN v_costo_total;
END;
$BODY$;


COMMENT ON FUNCTION public.calcular_costo_publicidad(integer, integer, integer, boolean, boolean, boolean, integer)
    IS 'Calcula el costo en poderes de una alarma publicitaria basándose en los parámetros configurados. Base: 40 poderes (100m, 1 día, 1 media).';
