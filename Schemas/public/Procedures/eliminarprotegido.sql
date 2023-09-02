-- PROCEDURE: public.eliminarprotegido(character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.eliminarprotegido(character varying, character varying);

CREATE OR REPLACE PROCEDURE public.eliminarprotegido(
	IN p_user_id_thirdparty_protector character varying,
	IN p_user_id_thirdparty_protegido character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE 
    v_persona_id_protector BIGINT;
	v_persona_id_protegido BIGINT;
	v_id_rel_protegido BIGINT;
	v_login_protector varchar(150);

BEGIN
    SELECT 
            persona_id,login
        INTO 
            v_persona_id_protector,v_login_protector
    FROM 
        personas
    WHERE
        user_id_thirdparty=p_user_id_thirdparty_protector;


    SELECT 
            persona_id
        INTO 
            v_persona_id_protegido
    FROM 
        personas
    WHERE
        user_id_thirdparty=p_user_id_thirdparty_protegido;

	select 
		rp.id_rel_protegido
	into 
		v_id_rel_protegido
	from 
		subscripciones s
	inner join 
		relacion_protegidos rp
	on 
		(
			s.id_rel_protegido=rp.id_rel_protegido and cast(now() as timestamp with time zone) between s.fecha_activacion and s.fecha_finalizacion
		)
	where 
		rp.id_persona_protegida=v_persona_id_protegido
	AND	
		rp.id_persona_protector=v_persona_id_protector;

	IF v_id_rel_protegido is null then
			RAISE EXCEPTION 'No existen subscripciones activas de protector-protegido. No es necesario eliminar al protegido ya que no tiene subscripcion vigente con él';	
	END IF;	

	delete from
		permisos_pendientes_protegidos
	where
		persona_id_protector=v_persona_id_protector
	AND
		persona_id_protegido=v_persona_id_protegido;

	update
        relacion_protegidos
    set
        fecha_finalizacion=cast(now() as timestamp with time zone)
    where
        id_persona_protegida=v_persona_id_protegido
	and 
		id_persona_protector=v_persona_id_protector;

	update
        subscripciones
    set
        fecha_finalizacion=cast(now() as timestamp with time zone)
		,observaciones='Se finaliza la subscripcion por solicitud del usuario PROTECTOR a través de la API desde la APP'
    where
        id_rel_protegido=v_id_rel_protegido
	and 
		persona_id=v_persona_id_protector;

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
				,'El usuario '||v_login_protector||' canceló definitivamente las subscripcion para seguir tus alarmas el día: '||cast(now() as timestamp with time zone)||'. El dinero y poderes invertidos en esa subscripción no son recuperables por esa acción'
				,now()
				,cast(true as boolean)
				,'Protector ya no sigue tus alarmas'
				,'es'
			);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION '%', sqlerrm;
END;
$BODY$;
ALTER PROCEDURE public.eliminarprotegido(character varying, character varying)
    OWNER TO w4ll4c3;
