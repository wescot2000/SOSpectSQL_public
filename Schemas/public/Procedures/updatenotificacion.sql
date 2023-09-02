-- PROCEDURE: public.updatenotificacion(character varying)

-- DROP PROCEDURE IF EXISTS public.updatenotificacion(character varying);

CREATE OR REPLACE PROCEDURE public.updatenotificacion(
	IN p_user_id_thirdparty character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
	v_persona_id BIGINT;
BEGIN
	BEGIN

		SELECT 
			persona_id
		INTO 
			v_persona_id
		FROM 
			personas
		WHERE
			user_id_thirdParty=p_user_id_thirdparty;



		UPDATE
			notificaciones_persona
		set
			flag_enviado=cast(true as boolean)
		WHERE
			persona_id=v_persona_id;
			
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.updatenotificacion(character varying)
    OWNER TO w4ll4c3;
