-- PROCEDURE: public.upsertubicacion(character varying, numeric, numeric)

-- DROP PROCEDURE IF EXISTS public.upsertubicacion(character varying, numeric, numeric);

CREATE OR REPLACE PROCEDURE public.upsertubicacion(
    IN p_user_id_thirdparty character varying,
    IN p_latitud numeric,
    IN p_longitud numeric,
    IN p_pais_id character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
    v_persona_id BIGINT;
    v_ubicacion_id BIGINT;
BEGIN
    -- Obtener el ID de la persona
    SELECT 
        persona_id
    INTO 
        v_persona_id
    FROM 
        personas
    WHERE
        user_id_thirdparty = p_user_id_thirdparty;

    -- Determinar el ID de la ubicación actual (si existe)
    SELECT 
        ubicacion_id
    INTO
        v_ubicacion_id
    FROM 
        ubicaciones
    WHERE
        persona_id = v_persona_id
        AND v_persona_id IS NOT NULL
        AND "Tipo" = 'P';

    -- Inserción para trazabilidad (puedes remover en producción)
    INSERT INTO 
        ubicaciones_testing
            (persona_id,
             latitud,
             longitud,
             fecha_ubicacion,
             pais_id)
    VALUES (
        v_persona_id,
        p_latitud,
        p_longitud,
        now(),
        p_pais_id
    );

    -- Si no existe una ubicación, inserta una nueva
    IF v_ubicacion_id IS NULL THEN
        INSERT INTO 
            ubicaciones 
                (
                    persona_id,
                    latitud,
                    longitud,
                    "Tipo",
                    pais_id
                )
        VALUES
            (
                v_persona_id,
                p_latitud,
                p_longitud,
                'P',
                p_pais_id
            );
    ELSE
        -- Si ya existe una ubicación, actualiza la existente
        UPDATE 
            ubicaciones
        SET 
            latitud = p_latitud,
            longitud = p_longitud,
            pais_id = p_pais_id
        WHERE
            "Tipo" = 'P'
        AND 
            ubicacion_id = v_ubicacion_id;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '%', sqlerrm;
END;
$BODY$;

    