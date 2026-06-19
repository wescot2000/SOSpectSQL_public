-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- PROCEDURE: public.enviarmensaje(character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.enviarmensaje(character varying, character varying);

CREATE OR REPLACE PROCEDURE public.enviarmensaje(
	IN p_asunto character varying,
	IN p_mensaje character varying)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
	v_cantidad BIGINT;
BEGIN
	BEGIN

	INSERT INTO
		mensajes_a_usuarios (persona_id,texto,fecha_mensaje,estado,asunto,idioma_origen,alarma_id) 
		SELECT 
			persona_id
			,p_mensaje
			,now()
			,cast(true as boolean)
			,p_asunto
			,'es'
			,null
		FROM 
			personas;
			
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;


