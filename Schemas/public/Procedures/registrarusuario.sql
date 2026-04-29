-- PROCEDURE: public.registrarusuario(character varying, character varying, character varying, character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.registrarusuario(character varying, character varying, character varying, character varying, character varying);

CREATE OR REPLACE PROCEDURE public.registrarusuario(
    IN p_login character varying,
    IN p_user_id_thirdparty character varying,
    IN p_registrationid character varying,
    IN p_plataforma character varying,
    IN p_idioma character varying,
    IN p_pais_id character varying
)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
    p_persona_id BIGINT;
    p_registrationidexistente INTEGER;
    p_persona_creada_id BIGINT;
    v_radio_alarmas_id INTEGER;
    v_id_dispositivo BIGINT;
    v_poderes_regalo INTEGER := 100;
    v_tiempo_refresco_mapa INTEGER := 60;
BEGIN
    BEGIN
        -- Obtener el ID del radio de alarmas por defecto
        SELECT 
            min(radio_alarmas_id) 
        INTO 
            v_radio_alarmas_id 
        FROM 
            radio_alarmas;

        -- Verificar si el usuario ya existe
        SELECT 
            persona_id
        INTO 
            p_persona_id
        FROM 
            personas
        WHERE
            user_id_thirdparty = p_user_id_thirdparty;
        
        -- Verificar si el dispositivo ya está registrado
        SELECT 
            id_dispositivo
        INTO
            v_id_dispositivo
        FROM
            dispositivos
        WHERE
            persona_id = p_persona_id
        AND 
            fecha_fin IS NULL;
        
        -- Si el usuario no existe, crear un nuevo registro en personas
        IF p_persona_id IS NULL THEN
            INSERT INTO 
                personas
                    (
                        radio_alarmas_id,
                        login,
                        user_id_thirdparty,
                        fechacreacion,
                        marca_bloqueo,
                        tiempo_refresco_mapa,
                        saldo_poderes,
                        Flag_es_policia
                    )
            VALUES 
                (
                    v_radio_alarmas_id,
                    p_login,
                    p_user_id_thirdparty,
                    CAST(now() AS date),
                    0,
                    v_tiempo_refresco_mapa,
                    v_poderes_regalo,
                    CAST(false AS boolean)
                );
        END IF;
        
        -- Obtener el ID de la persona recién creada o existente
        SELECT 
            persona_id
        INTO 
            p_persona_creada_id
        FROM 
            personas
        WHERE
            user_id_thirdparty = p_user_id_thirdparty;

        -- Registrar o actualizar el dispositivo
        IF v_id_dispositivo IS NULL THEN
            INSERT INTO 
                dispositivos
                    (
                        persona_id,
                        registrationid,
                        plataforma,
                        idioma,
                        fecha_inicio,
                        fecha_fin,
                        pais_id
                    )
            VALUES 
                (
                    p_persona_creada_id,
                    p_registrationid,
                    p_plataforma,
                    p_idioma,
                    CAST(now() AS timestamp with time zone),
                    CAST(NULL AS timestamp with time zone),
                    p_pais_id
                );
        ELSE
            UPDATE
                dispositivos
            SET	
                fecha_fin = now() - interval '1 second'
            WHERE 
                id_dispositivo = v_id_dispositivo;

            INSERT INTO 
                dispositivos
                    (
                        persona_id,
                        registrationid,
                        plataforma,
                        idioma,
                        fecha_inicio,
                        fecha_fin,
                        pais_id
                    )
            VALUES 
                (
                    p_persona_creada_id,
                    p_registrationid,
                    p_plataforma,
                    p_idioma,
                    CAST(now() AS timestamp with time zone),
                    CAST(NULL AS timestamp with time zone),
                    p_pais_id
                );
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION '%', sqlerrm;	
    END;
END
$BODY$;
