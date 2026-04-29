-- FUNCTION: public.llenar_informacion_inicial(character varying, character varying, character varying, character varying, character varying)

-- DROP FUNCTION IF EXISTS public.llenar_informacion_inicial(character varying, character varying, character varying, character varying, character varying);

CREATE OR REPLACE FUNCTION public.llenar_informacion_inicial(
    p_user_id_thirdparty character varying,
    p_nombres character varying,
    p_apellidos character varying,
    p_numero_movil character varying,
    p_email character varying,
    p_pais character varying,
    p_national_id character varying)
RETURNS TABLE(result character varying, message character varying) 
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
    -- Verificar si el usuario pertenece a la red de confianza
    IF EXISTS (
        SELECT 1
        FROM public.personas
        WHERE user_id_thirdparty = p_user_id_thirdparty
        AND flag_red_confianza = true
    ) THEN
        result := 'failure';
        message := 'El usuario ya forma parte de la red de confianza y su información no puede modificarse';
        RETURN NEXT;
    ELSE
        -- Actualizar la información del usuario
        UPDATE public.personas
        SET nombres = p_nombres,
            apellidos = p_apellidos,
            numero_movil = p_numero_movil,
            email = p_email,
            pais = COALESCE(NULLIF(pais, ''), p_pais),
            national_id = p_national_id
        WHERE user_id_thirdparty = p_user_id_thirdparty;

        result := 'success';
        message := 'Información del usuario actualizada exitosamente';
        RETURN NEXT;
    END IF;
END;
$BODY$;
