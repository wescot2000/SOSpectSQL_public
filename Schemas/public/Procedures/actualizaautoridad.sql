-- PROCEDURE: public.actualizaautoridad(character varying, boolean)

-- DROP PROCEDURE IF EXISTS public.actualizaautoridad(character varying, boolean);

CREATE OR REPLACE PROCEDURE public.actualizaautoridad(
	IN p_user_id_thirdparty character varying,
	IN p_accion boolean)
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
			personas
		set
			flag_es_policia=p_accion
		WHERE
			persona_id=v_persona_id;
			
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
