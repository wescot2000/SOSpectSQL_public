-- PROCEDURE: public.calificardescripcionesalarma(character varying, bigint, character varying)

-- DROP PROCEDURE IF EXISTS public.calificardescripcionesalarma(character varying, bigint, character varying);

CREATE OR REPLACE PROCEDURE public.calificardescripcionesalarma(
	IN p_user_id_thirdparty character varying,
	IN p_iddescripcion bigint,
	IN p_calificaciondescripcion character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
	p_persona_id BIGINT;
	p_validacion_existente INTEGER;
	p_calificacion_actual SMALLINT;
	v_calif_actual_desc VARCHAR(50);
	v_cambio_calificacion INTEGER;
	v_delta_calificacion INTEGER;
	v_alarma_id BIGINT;
	v_estado_alarma varchar(10);
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

		select
		   count(*)
		into 
			p_validacion_existente
		from 
			calificadores_descripcion cd
		where 
			cd.persona_id=p_persona_id
		and 
			cd.IdDescripcion=p_iddescripcion
		and 
			cd.calificacion=p_CalificacionDescripcion;

		IF p_validacion_existente > 0 then
			RAISE EXCEPTION 'The user had already rated this description';	
		END IF;	

		select
		   count(*)
		into 
			v_cambio_calificacion
		from 
			calificadores_descripcion cd
		where 
			cd.persona_id=p_persona_id
		and 
			cd.IdDescripcion=p_iddescripcion;

		SELECT
			COALESCE(CalificacionDescripcion,0), alarma_id
		into 
			p_calificacion_actual,v_alarma_id
		FROM
			DescripcionesAlarmas
		WHERE
			IdDescripcion=p_iddescripcion;

		SELECT
			estado_alarma
		INTO
			v_estado_alarma
		FROM
			alarmas
		WHERE
			alarma_id=v_alarma_id;

		IF v_estado_alarma = 'C' then
			RAISE EXCEPTION 'Denied, alarm already closed';	
		END IF;	

		select
		   calificacion
		into 
			v_calif_actual_desc
		from 
			calificadores_descripcion cd
		where 
			cd.persona_id=p_persona_id
		and 
			cd.IdDescripcion=p_iddescripcion;

		
		
		if v_cambio_calificacion>0 then 

			update 
				calificadores_descripcion
			set 
				calificacion=p_CalificacionDescripcion,
				fecha_calificacion=now()
			where 
				iddescripcion=p_iddescripcion
			AND	
				persona_id=p_persona_id;

		ELSE

			insert into 
				calificadores_descripcion
					(
						iddescripcion
						,persona_id
						,calificacion
						,fecha_calificacion					
					)
			values
				(
					p_iddescripcion
					,p_persona_id
					,p_CalificacionDescripcion
					,now()
				);
		end if;

		update 
			DescripcionesAlarmas
		set 
			CalificacionDescripcion=p_calificacion_actual+case when v_cambio_calificacion>0 and v_calif_actual_desc='Positivo' and p_CalificacionDescripcion='Negativo' then -2
									when v_cambio_calificacion>0 and v_calif_actual_desc='Positivo' and p_CalificacionDescripcion='Apagado' then -1
									when v_cambio_calificacion>0  and v_calif_actual_desc='Negativo' and p_CalificacionDescripcion='Positivo' then 2
									when v_cambio_calificacion>0  and v_calif_actual_desc='Negativo' and p_CalificacionDescripcion='Apagado' then 1
									when v_cambio_calificacion>0  and v_calif_actual_desc='Apagado' and p_CalificacionDescripcion='Positivo' then 1
									when v_cambio_calificacion>0  and v_calif_actual_desc='Apagado' and p_CalificacionDescripcion='Negativo' then -1
									when v_cambio_calificacion=0 and p_CalificacionDescripcion='Negativo' then -1
									when v_cambio_calificacion=0 and p_CalificacionDescripcion='Positivo' then 1
									end 
		where 
			IdDescripcion=p_iddescripcion;
		
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.calificardescripcionesalarma(character varying, bigint, character varying)
    OWNER TO w4ll4c3;
