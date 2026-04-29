-- FUNCTION: public.obtenersolicitudcierreactiva(bigint, character varying)

-- DROP FUNCTION IF EXISTS public.obtenersolicitudcierreactiva(bigint, character varying);

CREATE OR REPLACE FUNCTION public.obtenersolicitudcierreactiva(
	p_alarma_id bigint,
	p_user_id_thirdparty character varying)
RETURNS TABLE(
	solicitud_id bigint,
	alarma_id bigint,
	persona_id_solicitante bigint,
	descripcion character varying,
	fecha_solicitud timestamp with time zone,
	fecha_limite_votacion timestamp with time zone,
	estado character varying,
	votos_si integer,
	votos_no integer,
	es_proponente boolean,
	ya_voto_usuario boolean,
	voto_usuario boolean,
	fotos_json text
)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
	v_persona_id BIGINT;
BEGIN
	-- Obtener persona_id del usuario
	SELECT p.persona_id INTO v_persona_id
	FROM personas p
	WHERE p.user_id_thirdparty = p_user_id_thirdparty;

	RETURN QUERY
	SELECT
		sc.solicitud_id,
		sc.alarma_id,
		sc.persona_id AS persona_id_solicitante,
		sc.descripcion,
		sc.fecha_solicitud,
		sc.fecha_limite_votacion,
		sc.estado,
		sc.votos_si,
		sc.votos_no,
		(sc.persona_id = v_persona_id) AS es_proponente,
		CASE WHEN vc.voto_id IS NOT NULL THEN TRUE ELSE FALSE END AS ya_voto_usuario,
		vc.voto AS voto_usuario,
		COALESCE(
			(SELECT json_agg(json_build_object(
				'foto_id',       f.foto_id,
				'url_foto',      f.url_foto,
				'thumbnail_url', f.thumbnail_url,
				'es_video',      f.es_video,
				'orden',         f.orden
			) ORDER BY f.orden)::text
			FROM fotos_descripciones_alarmas f
			WHERE f.iddescripcion = sc.iddescripcion_propuesta
			  AND f.estado = 'A'),
			'[]'
		) AS fotos_json
	FROM solicitudes_cierre sc
	LEFT JOIN votos_cierre vc ON vc.solicitud_id = sc.solicitud_id AND vc.persona_id = v_persona_id
	WHERE sc.alarma_id = p_alarma_id
	AND sc.estado = 'activa';
END
$BODY$;

COMMENT ON FUNCTION public.obtenersolicitudcierreactiva(bigint, character varying) IS
'Retorna la solicitud de cierre activa para una alarma, incluyendo si el usuario ya votó, cuál fue su voto, si es el proponente del cierre (es_proponente), y las fotos de la propuesta (fotos_json). Modificado: 2026-04 — agregado es_proponente.';
