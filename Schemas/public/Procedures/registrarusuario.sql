-- PROCEDURE: public.registrarusuario(character varying, character varying, character varying, character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.registrarusuario(character varying, character varying, character varying, character varying, character varying);

CREATE OR REPLACE PROCEDURE public.registrarusuario(
	IN p_login character varying,
	IN p_user_id_thirdparty character varying,
	IN p_registrationid character varying,
	IN p_plataforma character varying,
	IN p_idioma character varying)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
	p_persona_id BIGINT;
	p_registrationidexistente INTEGER;
	p_persona_creada_id BIGINT;
	v_radio_alarmas_id INTEGER;
	v_id_dispositivo BIGINT;
	v_poderes_regalo INTEGER := 100;
	v_tiempo_refresco_mapa INTEGER := 60;
BEGIN
	BEGIN

		select 
			min(radio_alarmas_id) 
		into 
			v_radio_alarmas_id 
		from 
			radio_alarmas;

		SELECT 
				persona_id
			INTO 
				p_persona_id
		FROM 
			personas
		WHERE
			user_id_thirdparty=p_user_id_thirdparty;
			
		select 
			id_dispositivo
		INTO
			v_id_dispositivo
		FROM
			dispositivos
		where
			persona_id=p_persona_id
		and 
			fecha_fin is null;
			
		IF p_persona_id is null then
		INSERT INTO 
			personas
				(
					radio_alarmas_id
					,login
					,user_id_thirdparty
					,fechacreacion
					,marca_bloqueo
					,tiempo_refresco_mapa
					,saldo_poderes
				)
		
		VALUES 
			(
				v_radio_alarmas_id
				,p_login
				,p_user_id_thirdparty
				,CAST(now() as date)
				,0
				,v_tiempo_refresco_mapa
				,v_poderes_regalo
			);
		END IF;	
		
		SELECT 
				persona_id
			INTO 
				p_persona_creada_id
		FROM 
			personas
		WHERE
			user_id_thirdparty=p_user_id_thirdparty;
		

		if v_id_dispositivo IS NULL then
		
			INSERT INTO 
				dispositivos
					(
						persona_id
						,RegistrationId
						,plataforma
						,idioma
						,fecha_inicio
						,fecha_fin
					)
			VALUES 
				(
					p_persona_creada_id
					,p_RegistrationId
					,p_Plataforma
					,p_idioma
					,cast(now() as timestamp with time zone)
					,cast(null as timestamp with time zone)
				);
		
		ELSE

			UPDATE
				dispositivos
			SET	
				fecha_fin = now() - interval '1 second'
			WHERE 
				id_dispositivo=v_id_dispositivo;

			INSERT INTO 
				dispositivos
					(
						persona_id
						,RegistrationId
						,plataforma
						,idioma
						,fecha_inicio
						,fecha_fin
					)
			VALUES 
				(
					p_persona_creada_id
					,p_RegistrationId
					,p_Plataforma
					,p_idioma
					,cast(now() as timestamp with time zone)
					,cast(null as timestamp with time zone)
				);		
		
		END IF;	
		
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.registrarusuario(character varying, character varying, character varying, character varying, character varying)
    OWNER TO w4ll4c3;
