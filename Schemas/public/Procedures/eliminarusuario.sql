-- PROCEDURE: public.eliminarusuario(character varying)

-- DROP PROCEDURE IF EXISTS public.eliminarusuario(character varying);

CREATE OR REPLACE PROCEDURE public.eliminarusuario(
	IN p_user_id_thirdparty character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
	p_persona_id BIGINT;

BEGIN
	BEGIN
		SELECT 
				persona_id
			INTO 
				p_persona_id
		FROM 
			personas
		WHERE
			user_id_thirdparty=p_user_id_thirdparty;
			
			

		delete from dispositivos
		where persona_id=p_persona_id;

		delete from ubicaciones
		where persona_id=p_persona_id;


		delete from subscripciones
		where persona_id=p_persona_id;


		delete from descripcionesalarmas
		where persona_id=p_persona_id;

		delete from alarmas
		where persona_id=p_persona_id;

		delete from relacion_protegidos
		where id_persona_protector=p_persona_id;

		delete from relacion_protegidos
		where id_persona_protegida=p_persona_id;

		delete from personas
		where persona_id=p_persona_id;
		
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.eliminarusuario(character varying)
    OWNER TO w4ll4c3;
