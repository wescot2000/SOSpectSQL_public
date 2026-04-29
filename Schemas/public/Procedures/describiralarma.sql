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
	IN p_idioma character varying,
	IN p_fotos_json jsonb DEFAULT NULL)
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
	v_iddescripcion BIGINT;
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
					,flag_es_cierre_alarma
				)
		VALUES
			(
				p_persona_id
				,p_alarma_id
				,LEFT(p_DescripcionAlarma, 450)
                ,LEFT(p_DescripcionSospechoso, 450)
                ,LEFT(p_DescripcionVehiculo, 450)
                ,LEFT(p_DescripcionArmas, 450)
				,now()
				,v_latitud_originador
				,v_longitud_originador
				,p_IpUsuario
				,v_distancia_alarma_originador
				,p_idioma
				,cast(false as boolean)
			)
		RETURNING iddescripcion INTO v_iddescripcion;

		-- Insertar fotos si existen
		IF p_fotos_json IS NOT NULL THEN
			INSERT INTO fotos_descripciones_alarmas (
				iddescripcion,
				url_foto,
				nombre_archivo_original,
				tipo_mime,
				tamano_bytes,
				es_video,
				orden,
				bucket_s3
			)
			SELECT
				v_iddescripcion,
				(foto->>'url_foto')::varchar,
				(foto->>'nombre_archivo_original')::varchar,
				(foto->>'tipo_mime')::varchar,
				(foto->>'tamano_bytes')::bigint,
				(foto->>'es_video')::boolean,
				(foto->>'orden')::integer,
				'sospect-s3-data-bucket-prod'
			FROM jsonb_array_elements(p_fotos_json) AS foto;
		END IF;

		if v_tipoalarma_id_actual<>p_tipoalarma_id and p_persona_id=v_persona_id_creador and p_tipoalarma_id<>9 then

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
