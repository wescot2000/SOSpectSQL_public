-- PROCEDURE: public.updatenotificacion(character varying)

-- DROP PROCEDURE IF EXISTS public.updatenotificacion(character varying);

-- MODIFICACIÓN 2026-02-09: Actualizar timestamp para throttling de 10 minutos
CREATE OR REPLACE PROCEDURE public.updatenotificacion(
	IN p_user_id_thirdparty character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE
	v_persona_id BIGINT;
BEGIN
	BEGIN

		SELECT
			persona_id
		INTO
			v_persona_id
		FROM
			personas
		WHERE
			user_id_thirdParty=p_user_id_thirdparty;

		-- Marcar como enviado Y actualizar timestamp de última notificación
		UPDATE
			notificaciones_persona
		SET
			flag_enviado=cast(true as boolean),
			ultima_notificacion_enviada=NOW()
		WHERE
			persona_id=v_persona_id
			AND flag_enviado=FALSE;

		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;

	END;
END
$BODY$;
