-- FUNCTION: public.agregar_usuario_red_confianza(character varying, character varying, character varying)
-- Modificado: 2026-04-02 — Se agrega p_nickname para que el líder asigne un apodo al nuevo miembro.
--             El nickname se guarda en public.personas.nickname del usuario nuevo.

-- DROP FUNCTION IF EXISTS public.agregar_usuario_red_confianza(character varying, character varying, character varying);

CREATE OR REPLACE FUNCTION public.agregar_usuario_red_confianza(
    p_user_id_thirdparty_lider character varying,
    p_user_id_thirdparty_nuevo character varying,
    p_nickname character varying)
RETURNS TABLE(result character varying, message character varying) 
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE

AS $BODY$
DECLARE
    v_lider_id bigint;
    v_nuevo_id bigint;
    v_nombres character varying;
    v_apellidos character varying;
    v_numero_movil character varying;
    v_email character varying;
    v_national_id character varying;
    v_flag_red_confianza boolean;
    v_fecha_red_confianza timestamp;
BEGIN
    -- Obtener el persona_id y flag_red_confianza del líder
    SELECT persona_id, flag_red_confianza INTO v_lider_id, v_flag_red_confianza
    FROM public.personas
    WHERE user_id_thirdparty = p_user_id_thirdparty_lider;
    
    -- Validar que el líder tenga flag_red_confianza como verdadero
    IF v_flag_red_confianza IS NOT TRUE THEN
        result := 'failure';
        message := 'El líder no tiene el indicador de red de confianza establecido en verdadero';
        RETURN NEXT;
        RETURN; -- Para asegurar que la ejecución se detenga aquí
    END IF;

    -- Obtener los datos del nuevo usuario
    SELECT 
        persona_id, nombres, apellidos, numero_movil, email, national_id, flag_red_confianza, fecha_red_confianza
    INTO 
        v_nuevo_id, v_nombres, v_apellidos, v_numero_movil, v_email, v_national_id, v_flag_red_confianza, v_fecha_red_confianza
    FROM 
        public.personas
    WHERE 
        user_id_thirdparty = p_user_id_thirdparty_nuevo;

    -- Validar que los campos requeridos no sean nulos
    IF v_nombres IS NULL OR v_apellidos IS NULL OR v_numero_movil IS NULL OR v_email IS NULL OR v_national_id IS NULL THEN
        result := 'failure';
        message := 'Uno o más campos obligatorios son nulos';
        RETURN NEXT;
        RETURN; -- Para asegurar que la ejecución se detenga aquí
    END IF;

    -- Validar que el nuevo usuario tenga flag_red_confianza como nulo o falso y fecha_red_confianza como nulo
    IF v_flag_red_confianza IS TRUE OR v_fecha_red_confianza IS NOT NULL THEN
        result := 'failure';
        message := 'El nuevo usuario ya pertenece a una red de confianza';
        RETURN NEXT;
        RETURN; -- Para asegurar que la ejecución se detenga aquí
    END IF;

    -- Actualizar el campo persona_lider_redconf_id del nuevo usuario y guardar el nickname
    UPDATE public.personas
    SET persona_lider_redconf_id = v_lider_id,
        flag_red_confianza       = TRUE,
        fecha_red_confianza      = now(),
        nickname                 = p_nickname
    WHERE persona_id = v_nuevo_id;

    result := 'success';
    message := 'Usuario agregado a la red de confianza con éxito';
    RETURN NEXT;
END;
$BODY$;

