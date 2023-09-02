-- PROCEDURE: public.describiralarma(character varying, bigint, character varying, character varying, character varying, character varying, integer, character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.describiralarma(character varying, bigint, character varying, character varying, character varying, character varying, integer, character varying, character varying);

CREATE OR REPLACE PROCEDURE public.describiralarma(
	IN p_user_id_thirdparty character varying,
	IN p_alarma_id bigint,
	IN p_descripcionalarma character varying,
	IN p_descripcionsospechoso character varying,
	IN p_descripcionvehiculo character varying,
	IN p_descripcionarmas character varying,
	IN p_tipoalarma_id integer,
	IN p_ipusuario character varying,
	IN p_idioma character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
	p_persona_id BIGINT;
	v_persona_id_creador BIGINT;
	v_latitud_alarma numeric(9,6);
	v_longitud_alarma numeric(9,6);
	v_latitud_originador numeric(9,6);
	v_longitud_originador numeric(9,6);
	v_distancia_alarma_originador numeric(9,2);
	v_tipoalarma_id_actual INTEGER;
	v_estado_alarma VARCHAR(10);
BEGIN
	BEGIN
		/*INFORMACION DE LA ALARMA*/
		select 
			al.latitud,
			al.longitud,
			al.tipoalarma_id,
			al.persona_id,
			al.estado_alarma
		INTO
			v_latitud_alarma,
			v_longitud_alarma,
			v_tipoalarma_id_actual,
			v_persona_id_creador,
			v_estado_alarma
		FROM
			alarmas al
		where 
			al.alarma_id=p_alarma_id;

		IF v_estado_alarma = 'C' then
			RAISE EXCEPTION 'Denegado, alarma ya cerrada';	
		END IF;	

		/*INFORMACION DE QUIEN ESTA DESCRIBIENDO LA ALARMA*/
		SELECT 
			p.persona_id
			,u.latitud
			,u.longitud
			,ceiling(ABS((((v_latitud_alarma-u.latitud)+(v_longitud_alarma-u.longitud)*100)/0.000900))) as distancia_en_metros
		INTO 
			p_persona_id
			,v_latitud_originador
			,v_longitud_originador
			,v_distancia_alarma_originador
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
			descripcionesalarmas 
				(
					persona_id
					,alarma_id
					,DescripcionAlarma
					,DescripcionSospechoso
					,DescripcionVehiculo
					,DescripcionArmas
					,fechadescripcion
					,latitud_originador
					,longitud_originador
					,ip_usuario_originador
					,distancia_alarma_originador
					,idioma_origen
				)
		VALUES
			(
				p_persona_id
				,p_alarma_id
				,p_DescripcionAlarma
				,p_DescripcionSospechoso
				,p_DescripcionVehiculo
				,p_DescripcionArmas
				,now()
				,v_latitud_originador
				,v_longitud_originador
				,p_IpUsuario
				,v_distancia_alarma_originador
				,p_idioma
			);	

		if v_tipoalarma_id_actual<>p_tipoalarma_id and p_persona_id=v_persona_id_creador then

			update 
				alarmas
			set
				tipoalarma_id=p_tipoalarma_id
			WHERE
				alarma_id=p_alarma_id;

		end if;


		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;
	END;
		
END
$BODY$;
ALTER PROCEDURE public.describiralarma(character varying, bigint, character varying, character varying, character varying, character varying, integer, character varying, character varying)
    OWNER TO w4ll4c3;
