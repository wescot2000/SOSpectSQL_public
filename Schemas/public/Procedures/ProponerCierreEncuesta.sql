-- PROCEDURE: public.proponercierreencuesta(bigint, character varying, character varying, character varying)

-- DROP PROCEDURE IF EXISTS public.proponercierreencuesta(bigint, character varying, character varying, character varying);

CREATE OR REPLACE PROCEDURE public.proponercierreencuesta(
	IN p_alarma_id bigint,
	IN p_user_id_thirdparty character varying,
	IN p_descripcion character varying,
	IN p_idioma character varying,
	INOUT p_solicitud_id bigint DEFAULT NULL)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
	v_persona_id BIGINT;
	v_estado_alarma VARCHAR(10);
	v_tipo_cierre VARCHAR(20);
	v_tipoalarma_id INTEGER;
	v_solicitud_activa_id BIGINT;
BEGIN
	-- Obtener persona_id del usuario
	SELECT p.persona_id INTO v_persona_id
	FROM personas p
	WHERE p.user_id_thirdparty = p_user_id_thirdparty;

	IF v_persona_id IS NULL THEN
		RAISE EXCEPTION 'User not found';
	END IF;

	-- Obtener datos de la alarma
	SELECT al.estado_alarma, al.tipoalarma_id
	INTO v_estado_alarma, v_tipoalarma_id
	FROM alarmas al
	WHERE al.alarma_id = p_alarma_id;

	IF v_estado_alarma = 'C' THEN
		RAISE EXCEPTION 'Denied, alarm already closed';
	END IF;

	-- Validar que es tipo cierre_encuesta
	SELECT ta.tipo_cierre INTO v_tipo_cierre
	FROM tipoalarma ta
	WHERE ta.tipoalarma_id = v_tipoalarma_id;

	IF v_tipo_cierre <> 'cierre_encuesta' THEN
		RAISE EXCEPTION 'Denied, this alarm type does not support community poll closure';
	END IF;

	-- Verificar que no exista solicitud activa
	SELECT sc.solicitud_id INTO v_solicitud_activa_id
	FROM solicitudes_cierre sc
	WHERE sc.alarma_id = p_alarma_id AND sc.estado = 'activa';

	IF v_solicitud_activa_id IS NOT NULL THEN
		RAISE EXCEPTION 'Denied, there is already an active closure request for this alarm';
	END IF;

	-- Insertar solicitud de cierre
	INSERT INTO solicitudes_cierre (
		alarma_id,
		persona_id,
		descripcion,
		fecha_solicitud,
		fecha_limite_votacion,
		estado,
		votos_si,
		votos_no
	) VALUES (
		p_alarma_id,
		v_persona_id,
		p_descripcion,
		now(),
		now() + interval '24 hours',
		'activa',
		0,
		0
	) RETURNING solicitud_id INTO p_solicitud_id;

END
$BODY$;
