-- FUNCTION: public.consultar_usuario_para_red_confianza(character varying)
-- MODIFICADO: 2026-02-26 - Resolver nombre del país desde tabla paises (ISO alpha-2 → nombre legible)
--   personas.pais ahora almacena ISO alpha-2 (CO, MX); la UI requiere el nombre en español

-- DROP FUNCTION IF EXISTS public.consultar_usuario_para_red_confianza(character varying);

CREATE OR REPLACE FUNCTION public.consultar_usuario_para_red_confianza(
    p_user_id_thirdparty character varying)
RETURNS TABLE(result character varying, message character varying, user_id_thirdparty character varying, national_id character varying, nombres character varying, apellidos character varying, email character varying, pais character varying, numero_movil character varying)
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE

AS $BODY$
DECLARE
    v_user RECORD;
BEGIN
    -- Buscar el usuario por su user_id_thirdparty
    -- JOIN con paises para resolver ISO alpha-2 → nombre en español
    SELECT
        p.user_id_thirdparty,
        p.national_id,
        p.nombres,
        p.apellidos,
        p.email,
        COALESCE(pa.nombre_es, p.pais) AS pais,  -- nombre legible si existe en tabla paises, sino el valor raw
        p.numero_movil,
        p.flag_red_confianza
    INTO v_user
    FROM
        public.personas p
    LEFT JOIN public.paises pa ON pa.pais_id = p.pais
    WHERE
        p.user_id_thirdparty = p_user_id_thirdparty;

    -- Verificar si el usuario fue encontrado
    IF NOT FOUND THEN
        result := 'failure';
        message := 'No se encontró ningún usuario con el ID de usuario de terceros proporcionado';
        RETURN QUERY SELECT
            result,
            message,
            NULL::character varying,
            NULL::character varying,
            NULL::character varying,
            NULL::character varying,
            NULL::character varying,
            NULL::character varying,
            NULL::character varying;
    END IF;

    -- Verificar si el usuario ya forma parte de la red de confianza
    IF v_user.flag_red_confianza IS TRUE THEN
        result := 'failure';
        message := 'El usuario ya es parte de la red de confianza';
        RETURN QUERY SELECT
            result,
            message,
            v_user.user_id_thirdparty,
            v_user.national_id,
            v_user.nombres,
            v_user.apellidos,
            v_user.email,
            v_user.pais,
            v_user.numero_movil;
    END IF;

    -- Verificar si falta información personal
    IF v_user.national_id IS NULL OR v_user.numero_movil IS NULL OR v_user.pais IS NULL OR v_user.nombres IS NULL OR v_user.apellidos IS NULL OR v_user.email IS NULL THEN
        result := 'failure';
        message := 'La información personal del usuario que se agregará a la red de confianza está incompleta';
        RETURN QUERY SELECT
            result,
            message,
            v_user.user_id_thirdparty,
            v_user.national_id,
            v_user.nombres,
            v_user.apellidos,
            v_user.email,
            v_user.pais,
            v_user.numero_movil;
    END IF;

    -- Si todas las condiciones son satisfechas, retornar la información del usuario
    result := 'success';
    message := 'La información personal del usuario que se agregará a la red de confianza está completa y el usuario aún no forma parte de la red de confianza';
    RETURN QUERY SELECT
        result,
        message,
        v_user.user_id_thirdparty,
        v_user.national_id,
        v_user.nombres,
        v_user.apellidos,
        v_user.email,
        v_user.pais,
        v_user.numero_movil;
END;
$BODY$;

