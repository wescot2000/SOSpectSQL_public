-- PROCEDURE: public.votarcierreencuesta(bigint, character varying, boolean)

-- DROP PROCEDURE IF EXISTS public.votarcierreencuesta(bigint, character varying, boolean);

CREATE OR REPLACE PROCEDURE public.votarcierreencuesta(
	IN p_solicitud_id bigint,
	IN p_user_id_thirdparty character varying,
	IN p_voto boolean)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
	v_persona_id BIGINT;
	v_persona_id_proponente BIGINT;
	v_estado_solicitud VARCHAR(20);
	v_fecha_limite TIMESTAMP WITH TIME ZONE;
	v_ya_voto BOOLEAN;
BEGIN
	-- Obtener persona_id del usuario
	SELECT p.persona_id INTO v_persona_id
	FROM personas p
	WHERE p.user_id_thirdparty = p_user_id_thirdparty;

	IF v_persona_id IS NULL THEN
		RAISE EXCEPTION 'User not found';
	END IF;

	-- Obtener datos de la solicitud (incluye persona_id del proponente para validación anti-fraude)
	SELECT sc.estado, sc.fecha_limite_votacion, sc.persona_id
	INTO v_estado_solicitud, v_fecha_limite, v_persona_id_proponente
	FROM solicitudes_cierre sc
	WHERE sc.solicitud_id = p_solicitud_id;

	IF v_estado_solicitud IS NULL THEN
		RAISE EXCEPTION 'Closure request not found';
	END IF;

	IF v_estado_solicitud <> 'activa' THEN
		RAISE EXCEPTION 'Denied, closure request is no longer active';
	END IF;

	IF now() > v_fecha_limite THEN
		RAISE EXCEPTION 'Denied, voting period has expired';
	END IF;

	-- ANTI-FRAUDE: el proponente no puede votar en su propia solicitud de cierre.
	-- Esta validación es la defensa server-side contra clientes comprometidos
	-- (APK modificado, llamada directa al API, etc.) que intenten saltarse la
	-- restricción que ya impone la UI (CierreEncuestaPage oculta los botones de voto
	-- cuando es_proponente=true). 2026-04 — agregado por requisito anti-corrupción.
	IF v_persona_id = v_persona_id_proponente THEN
		RAISE EXCEPTION 'Denied, the proposer cannot vote on their own closure request';
	END IF;

	-- Verificar que el usuario no haya votado ya
	SELECT EXISTS(
		SELECT 1 FROM votos_cierre vc
		WHERE vc.solicitud_id = p_solicitud_id AND vc.persona_id = v_persona_id
	) INTO v_ya_voto;

	IF v_ya_voto THEN
		RAISE EXCEPTION 'Denied, user has already voted on this closure request';
	END IF;

	-- Insertar voto
	INSERT INTO votos_cierre (
		solicitud_id,
		persona_id,
		voto,
		fecha_voto
	) VALUES (
		p_solicitud_id,
		v_persona_id,
		p_voto,
		now()
	);

	-- Actualizar contadores en solicitud
	IF p_voto = TRUE THEN
		UPDATE solicitudes_cierre
		SET votos_si = votos_si + 1
		WHERE solicitud_id = p_solicitud_id;
	ELSE
		UPDATE solicitudes_cierre
		SET votos_no = votos_no + 1
		WHERE solicitud_id = p_solicitud_id;
	END IF;

END
$BODY$;
