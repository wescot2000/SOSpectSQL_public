-- PROCEDURE: public.insertaalarma(character varying, integer, numeric, numeric, character varying, bigint)

-- DROP PROCEDURE IF EXISTS public.insertaalarma(character varying, integer, numeric, numeric, character varying, bigint);

CREATE OR REPLACE PROCEDURE public.insertaalarma(
	IN p_user_id_thirdparty character varying,
	IN p_tipoalarma_id integer,
	IN p_latitud numeric,
	IN p_longitud numeric,
	IN p_ipusuario character varying,
	IN p_alarma_id bigint)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
	p_persona_id BIGINT;
	v_latitud_originador numeric(9,6);
	v_longitud_originador numeric(9,6);
	v_distancia_alarma_originador numeric(9,2);
	v_credibilidad_persona numeric(5,2);
BEGIN
	BEGIN
		SELECT 
			p.persona_id
			,u.latitud
			,u.longitud
			,ceiling(ABS((((p_latitud-u.latitud)+(p_longitud-u.longitud)*100)/0.000900))) as distancia_en_metros
			,credibilidad_persona
		INTO 
			p_persona_id
			,v_latitud_originador
			,v_longitud_originador
			,v_distancia_alarma_originador
			,v_credibilidad_persona
		FROM 
			personas p
		left outer join 
			ubicaciones u
		on
			(
				p.persona_id=u.persona_id
				and u."Tipo"='P'
			)
		WHERE 
			user_id_thirdparty=p_user_id_thirdparty;
		
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE EXCEPTION 'Persona % no encontrada', p_user_id_thirdparty;
			WHEN TOO_MANY_ROWS THEN
				RAISE EXCEPTION 'Persona % no es unica', p_user_id_thirdparty;
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;
	END;

	BEGIN
		INSERT INTO 
			alarmas 
				(
					persona_id, 
					tipoalarma_id, 
					fecha_alarma, 
					latitud, 
					longitud,
					latitud_originador,
					longitud_originador,
					ip_usuario_originador,
					distancia_alarma_originador,
					alarma_id_padre,
					calificacion_alarma 
				) 
				VALUES 
				(
					p_persona_id,
					p_tipoalarma_id, 
					now(),
					p_latitud,
					p_longitud,
					v_latitud_originador,
					v_longitud_originador,
					p_IpUsuario,
					v_distancia_alarma_originador,
					p_alarma_id,
					v_credibilidad_persona
				);
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;
	END;
	
END
$BODY$;
ALTER PROCEDURE public.insertaalarma(character varying, integer, numeric, numeric, character varying, bigint)
    OWNER TO w4ll4c3;
