-- PROCEDURE: public.marcapersonascomplices()

-- DROP PROCEDURE IF EXISTS public.marcapersonascomplices();

CREATE OR REPLACE PROCEDURE public.marcapersonascomplices(
	)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
	p_persona_id BIGINT;
BEGIN
	BEGIN
	
		UPDATE 
			personas 
		SET 
			marca_bloqueo=b.marca_bloqueo+1, fecha_ultima_marca_bloqueo=now()
  		FROM  
			(  
				select 
					per.persona_id
					,marca_bloqueo
				from 
					(
						select 
							des.persona_id 
						from 
							alarmas al
						inner join 
							descripcionesalarmas des
						on 
							(
								al.alarma_id=des.alarma_id
							)
						WHERE 
							al.fecha_alarma> now()- interval '1 day'
						AND 
							al.calificacion_alarma>60.0
						and 
							des.veracidadalarma is false
						and
							al.estado_alarma='C'
						group by 1
					) as deriv
				inner join 
					personas per
				on 
					(
						per.PERSONA_ID=deriv.PERSONA_ID
					)
			) B
		WHERE 
			personas.persona_id = B.persona_id
		AND
			COALESCE(personas.fecha_ultima_marca_bloqueo,now()-interval '100 day')<now()-interval '1 day';
			
		UPDATE 
			personas 
		SET 
			marca_bloqueo=deriv.marca_bloqueo+1, fecha_ultima_marca_bloqueo=now()
		FROM  
			(
				select 
					al.persona_id
					,per.marca_bloqueo
				from 
					alarmas al
				inner join 
					personas per
				on 
					(
						per.PERSONA_ID=al.PERSONA_ID
					)
				where 
					estado_alarma='C'
				AND 
					al.calificacion_alarma<60.0
				and 
					al.fecha_alarma> now()- interval '1 day'
			) as deriv
		WHERE 
			personas.persona_id = deriv.persona_id;
	
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;
	END;
		
END
$BODY$;
ALTER PROCEDURE public.marcapersonascomplices()
    OWNER TO w4ll4c3;
