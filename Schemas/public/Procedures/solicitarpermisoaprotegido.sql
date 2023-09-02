-- PROCEDURE: public.solicitarpermisoaprotegido(character varying, character varying, integer, integer)

-- DROP PROCEDURE IF EXISTS public.solicitarpermisoaprotegido(character varying, character varying, integer, integer);

CREATE OR REPLACE PROCEDURE public.solicitarpermisoaprotegido(
	IN p_user_id_thirdparty_protector character varying,
	IN p_user_id_thirdparty_protegido character varying,
	IN p_tiempo_subscripcion_dias integer,
	IN p_tiporelacionid integer)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
    v_persona_id_protector bigint;
	v_persona_id_protegido bigint;
	v_cantidad_solicitudes INTEGER;
	v_login_protector varchar(150);
	v_tipo_relacion INTEGER;
	v_descripcion_tipo varchar(150);

BEGIN
    SELECT 
            persona_id,login
        INTO 
            v_persona_id_protector,v_login_protector
    FROM 
        personas
    WHERE
        user_id_thirdparty=p_user_id_thirdparty_protector;

	select 
		tiporelacion_id ,descripciontiporel
	into 
		v_tipo_relacion ,v_descripcion_tipo
	from 
		tiporelacion 
	where 
		tiporelacion_id=p_TiporelacionId;

	IF v_tipo_relacion is null then
			RAISE EXCEPTION 'Tipo de relacion incorrecto.';	
	END IF;	

	SELECT 
            persona_id
        INTO 
            v_persona_id_protegido
    FROM 
        personas
    WHERE
        user_id_thirdparty=p_user_id_thirdparty_protegido;

	IF v_persona_id_protegido is null then
			RAISE EXCEPTION 'El usuario que quiere proteger no existe en la aplicacion o no se ha registrado aún';	
	END IF;	

	SELECT
		COUNT(*)
	INTO
		v_cantidad_solicitudes
	FROM 
		permisos_pendientes_protegidos
	WHERE
		persona_id_protegido=v_persona_id_protegido
	AND 
		flag_aprobado IS FALSE
	AND 
		fecha_aprobado IS NULL;

	IF v_cantidad_solicitudes > 0 then
			RAISE EXCEPTION 'El usuario que quiere proteger ya tiene otra solicitud pendiente y solo se puede tener una. Reintente posteriormente cuando el usuario haya aprobado la solicitud pendiente.';	
	END IF;	

		delete from
			permisos_pendientes_protegidos
		where
			persona_id_protector=v_persona_id_protector
		AND
			persona_id_protegido=v_persona_id_protegido;

		insert into permisos_pendientes_protegidos
			(
				persona_id_protector
				,persona_id_protegido
				,tiempo_subscripcion_dias
				,fecha_solicitud
				,tiporelacion_id
			)
		VALUES
			(
				v_persona_id_protector
				,v_persona_id_protegido
				,p_tiempo_subscripcion_dias
				,now()
				,v_tipo_relacion
			);

		INSERT INTO 
			mensajes_a_usuarios
				(
					persona_id
					,texto
					,fecha_mensaje
					,estado
					,asunto
					,idioma_origen
				)
			VALUES
				(
					v_persona_id_protegido
					,'El usuario '||v_login_protector||' solicitó seguir tus alarmas el día: '||cast(now() as timestamp with time zone)||'. Indica que su relacion contigo es de: '||v_descripcion_tipo||'. Para aprobarlo entra a menú, gestionar mis protegidos-protectores y aprobar solicitud de protector'
					,now()
					,cast(true as boolean)
					,v_login_protector||' solicita tu aprobacion para seguir tus alarmas'
					,'es'
				);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION '%', sqlerrm;
END;
$BODY$;
ALTER PROCEDURE public.solicitarpermisoaprotegido(character varying, character varying, integer, integer)
    OWNER TO w4ll4c3;
