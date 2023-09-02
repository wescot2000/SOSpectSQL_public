-- PROCEDURE: public.marcamensajeleido(character varying, bigint)

-- DROP PROCEDURE IF EXISTS public.marcamensajeleido(character varying, bigint);

CREATE OR REPLACE PROCEDURE public.marcamensajeleido(
	IN p_user_id_thirdparty character varying,
	IN p_mensaje_id bigint)
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
			mensajes_a_usuarios
		set
			estado=cast(false as boolean)
		WHERE
			mensaje_id=p_mensaje_id
		and 
			persona_id=v_persona_id;
			
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.marcamensajeleido(character varying, bigint)
    OWNER TO w4ll4c3;
