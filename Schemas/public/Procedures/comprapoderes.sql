-- PROCEDURE: public.comprapoderes(character varying, integer, numeric, character varying, character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.comprapoderes(character varying, integer, numeric, character varying, character varying, character varying);

CREATE OR REPLACE PROCEDURE public.comprapoderes(
	IN p_user_id_thirdparty character varying,
	IN p_cantidad integer,
	IN p_valor numeric,
	IN p_ip_transaccion character varying,
	IN p_purchase_token character varying,
	IN p_tipo_transaccion character varying)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
	v_persona_id bigint;
	v_poder_id INTEGER;
	v_saldo_actual_poderes INTEGER;
BEGIN
	BEGIN

		SELECT 
				persona_id
			INTO 
				v_persona_id
		FROM 
			personas
		WHERE
			user_id_thirdparty=p_user_id_thirdparty;

		SELECT
			poder_id
		INTO
			v_poder_id
		FROM
			poderes p
		where 
			p.cantidad=p_cantidad;

		select 
			saldo_poderes
		INTO
			v_saldo_actual_poderes
		from
			personas
		WHERE
			persona_id=v_persona_id;

		INSERT INTO
			transacciones_personas
				(
					persona_id
					,poder_id
					,fecha_transaccion
					,ip_transaccion
					,tipo_transaccion
					,purchase_token
				)
			VALUES
				(
					v_persona_id
					,v_poder_id
					,now()
					,p_ip_transaccion
					,p_tipo_transaccion
					,p_purchase_token
				);

		UPDATE
			personas
		SET
			saldo_poderes=v_saldo_actual_poderes+p_cantidad
		WHERE	
			persona_id=v_persona_id;

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
					v_persona_id
					,'¡GRACIAS POR TU COMPRA! Adquiriste '||p_cantidad||' poderes por valor de '||p_valor||'. Con estos poderes puedes adquirir las subscripciones que encuentras ingresando al menú principal.'
					,now()
					,cast(True as boolean)
					,'Realizaste compra de poderes exitosamente'
					,'es'
				);
		
		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;	
		
	END;
END
$BODY$;
ALTER PROCEDURE public.comprapoderes(character varying, integer, numeric, character varying, character varying, character varying)
    OWNER TO w4ll4c3;
