-- PROCEDURE: public.aprobarpermisoaprotector(character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.aprobarpermisoaprotector(character varying, character varying);

CREATE OR REPLACE PROCEDURE public.aprobarpermisoaprotector(
	IN p_user_id_thirdparty_protegido character varying,
	IN p_user_id_thirdparty_protector character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
    
	v_persona_id_protegido bigint;
	v_permiso_pendiente_id bigint;
	v_persona_id_protector bigint;
	v_login_protegido VARCHAR(150);

BEGIN
    SELECT 
            persona_id,login
        INTO 
            v_persona_id_protegido,v_login_protegido
    FROM 
        personas
    WHERE
        user_id_thirdparty=p_user_id_thirdparty_protegido;

	SELECT 
            persona_id
        INTO 
            v_persona_id_protector
    FROM 
        personas
    WHERE
        user_id_thirdparty=p_user_id_thirdparty_protector;


	SELECT 
            permiso_pendiente_id
        INTO 
            v_permiso_pendiente_id
    FROM 
        permisos_pendientes_protegidos
    WHERE
        persona_id_protegido=v_persona_id_protegido
	AND
		persona_id_protector=v_persona_id_protector
	and 
		flag_aprobado is false
	and 
		fecha_aprobado is null;


    IF v_permiso_pendiente_id is null then
			RAISE EXCEPTION 'No hay solicitudes pendientes de aprobacion. Si la aplicacion sigue indicando que tiene una solicitud pendiente, por favor describa el problema a soporte@wescot.com.co enviando su id de usuario. Gracias.';	
	END IF;	

	update
        permisos_pendientes_protegidos
    set
        flag_aprobado=true
		,fecha_aprobado=now()
    where
        permiso_pendiente_id=v_permiso_pendiente_id
	and 
		flag_aprobado is false
	and 
		fecha_aprobado is null;

	INSERT INTO 
		mensajes_a_usuarios
			(
				persona_id
				,texto
				,fecha_mensaje
				,estado
				,asunto
				,idioma_origen
			)
		VALUES
			(
				v_persona_id_protector
				,'El usuario '||v_login_protegido||' aprobó tu solicitud para seguir sus alarmas el día: '||cast(now() as timestamp with time zone)||'. Puedes continuar con el proceso de subscripción en menú, gestionar mis protegidos-protectores y completar trámite.'
				,now()
				,cast(true as boolean)
				,v_login_protegido||' ha aprobado tu solicitud para seguir sus alarmas'
				,'es'
			);


    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION '%', sqlerrm;
END;
$BODY$;
ALTER PROCEDURE public.aprobarpermisoaprotector(character varying, character varying)
    OWNER TO w4ll4c3;
