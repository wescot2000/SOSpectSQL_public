-- PROCEDURE: public.aceptacioncondiciones(character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.aceptacioncondiciones(character varying, character varying);

CREATE OR REPLACE PROCEDURE public.aceptacioncondiciones(
	IN p_user_id_thirdparty character varying,
	IN p_ip_aceptacion character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
	p_persona_id BIGINT;
	p_contrato_id INTEGER;
	p_validacion_existente INTEGER;
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
			aceptacion_condiciones ac
		inner join 
			condiciones_servicio cs 
		on 
			(
				ac.contrato_id=cs.contrato_id and cs.fecha_fin_version is null
			)
		where 
			ac.persona_id=p_persona_id;

		IF p_validacion_existente > 0 then
			RAISE EXCEPTION 'El usuario ya tiene la ultima version de contrato firmado';	
		END IF;	
			

		SELECT 
				contrato_id
			INTO 
				p_contrato_id
		FROM 
			condiciones_servicio
		WHERE
			fecha_fin_version is null;			
	
	
		insert into 
			aceptacion_condiciones
				(
					persona_id
					,contrato_id
					,fecha_aceptacion
					,ip_aceptacion
				)
		values
			(
				p_persona_id
				,p_contrato_id
				,now()
				,p_ip_aceptacion
			);
		
		
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.aceptacioncondiciones(character varying, character varying)
    OWNER TO w4ll4c3;
