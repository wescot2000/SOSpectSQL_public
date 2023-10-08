-- PROCEDURE: public.eliminarusuario(character varying)

-- DROP PROCEDURE IF EXISTS public.eliminarusuario(character varying);

CREATE OR REPLACE PROCEDURE public.eliminarusuario(
	IN p_user_id_thirdparty character varying)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
	p_persona_id BIGINT;

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
			
		delete from calificadores_descripcion	
		where iddescripcion in (select iddescripcion from descripcionesalarmas where persona_id=p_persona_id);

		delete from calificadores_descripcion	
		where iddescripcion in (select iddescripcion from descripcionesalarmas where alarma_id in (select alarma_id from alarmas where persona_id=p_persona_id));

		delete from dispositivos
		where persona_id=p_persona_id;

		delete from ubicaciones
		where persona_id=p_persona_id;

		delete from descripcionesalarmas
		where persona_id=p_persona_id;

		delete from notificaciones_persona
		where alarma_id in (select alarma_id from alarmas where persona_id=p_persona_id);

		delete from descripcionesalarmas
		where alarma_id in (select alarma_id from alarmas where persona_id=p_persona_id);

		delete from mensajes_a_usuarios
		where persona_id=p_persona_id;

		delete from mensajes_a_usuarios
		where alarma_id in (select alarma_id from alarmas where persona_id=p_persona_id);

		delete from alarmas
		where persona_id=p_persona_id;

		delete from subscripciones
		where id_rel_protegido in (select id_rel_protegido from relacion_protegidos where id_persona_protector=p_persona_id);

		delete from subscripciones
		where id_rel_protegido in (select id_rel_protegido from relacion_protegidos where id_persona_protegida=p_persona_id);

		delete from relacion_protegidos
		where id_persona_protector=p_persona_id;

		delete from relacion_protegidos
		where id_persona_protegida=p_persona_id;

		delete from subscripciones
		where persona_id=p_persona_id;

		delete from transacciones_personas
		where persona_id=p_persona_id;

		delete from aceptacion_condiciones
		where persona_id=p_persona_id;

		delete from permisos_pendientes_protegidos
		where persona_id_protector=p_persona_id;

		delete from permisos_pendientes_protegidos
		where persona_id_protegido=p_persona_id;

		delete from notificaciones_persona
		where persona_id=p_persona_id;

		delete from poderes_regalados
		where persona_id=p_persona_id;

		delete from personas
		where persona_id=p_persona_id;
		
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.eliminarusuario(character varying)
    OWNER TO w4ll4c3;
