-- FUNCTION: public.contar_usuarios_en_radio(numeric, numeric, integer)

-- DROP FUNCTION IF EXISTS public.contar_usuarios_en_radio(numeric, numeric, integer);

CREATE OR REPLACE FUNCTION public.contar_usuarios_en_radio(
    p_latitud numeric,
    p_longitud numeric,
    p_radio_metros integer)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    v_count INTEGER;
BEGIN
    -- Contar usuarios únicos con dispositivos activos cuya última ubicación conocida está dentro del radio
    -- Usando la fórmula de Haversine para calcular distancia en metros
    -- IMPORTANTE: Solo cuenta usuarios con al menos un dispositivo activo (fecha_fin IS NULL)
    SELECT COUNT(DISTINCT u.persona_id)
    INTO v_count
    FROM ubicaciones u
    INNER JOIN personas p ON u.persona_id = p.persona_id
    WHERE EXISTS (
        SELECT 1
        FROM dispositivos d
        WHERE d.persona_id = u.persona_id
          AND d.fecha_fin IS NULL
    )
    AND (
        6371000 * acos(
            cos(radians(p_latitud)) *
            cos(radians(u.latitud)) *
            cos(radians(u.longitud) - radians(p_longitud)) +
            sin(radians(p_latitud)) *
            sin(radians(u.latitud))
        )
    ) <= p_radio_metros;

    RETURN COALESCE(v_count, 0);
END;
$BODY$;


COMMENT ON FUNCTION public.contar_usuarios_en_radio(numeric, numeric, integer)
    IS 'Cuenta la cantidad de usuarios únicos dentro de un radio geográfico específico, basándose en su última ubicación conocida.';
