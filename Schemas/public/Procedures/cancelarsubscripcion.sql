-- PROCEDURE: public.cancelarsubscripcion(bigint, character varying)

-- DROP PROCEDURE IF EXISTS public.cancelarsubscripcion(bigint, character varying);

CREATE OR REPLACE PROCEDURE public.cancelarsubscripcion(
	IN p_subscripcion_id bigint,
	IN p_user_id_thirdparty_protector character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
	v_persona_id BIGINT;
	v_id_rel_protegido BIGINT;
	v_ubicacion_id BIGINT;
BEGIN
	BEGIN

		SELECT 
			persona_id
		INTO 
			v_persona_id
		FROM 
			personas
		WHERE
			user_id_thirdParty=p_user_id_thirdparty_protector;

		SELECT
			id_rel_protegido
		into 
			v_id_rel_protegido
		from 
			subscripciones
		where 
			subscripcion_id=p_subscripcion_id;
		
		SELECT
			ubicacion_id
		into 
			v_ubicacion_id
		from 
			subscripciones
		where 
			subscripcion_id=p_subscripcion_id;

		if v_id_rel_protegido is not null then
			
			UPDATE
				relacion_protegidos
			set
				fecha_finalizacion=cast(now() as timestamp with time zone)
			WHERE
				id_rel_protegido=v_id_rel_protegido;

		end if;

		if v_ubicacion_id is not null then
			
			DELETE FROM
				ubicaciones
			WHERE
				ubicacion_id=v_ubicacion_id
			and 
				"Tipo"='S';

		end if;

		UPDATE
			subscripciones
		set
			fecha_finalizacion=cast(now() as timestamp with time zone)
		WHERE
			subscripcion_id=p_subscripcion_id;
			
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.cancelarsubscripcion(bigint, character varying)
    OWNER TO w4ll4c3;
