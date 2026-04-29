-- PROCEDURE: public.actualizaparametrosnotificacion(character varying, boolean, boolean, boolean, boolean, integer, integer, integer, text[])
-- MODIFICADO: 2026-02-26 - Agregar p_paises_feed_filtro para filtro de países en feed "Para Ti"

-- DROP PROCEDURE IF EXISTS public.actualizaparametrosnotificacion(character varying, boolean, boolean, boolean, boolean, integer, integer, integer, text[]);

CREATE OR REPLACE PROCEDURE public.actualizaparametrosnotificacion(
	IN p_user_id_thirdparty character varying,
	IN p_notif_alarma_cercana_habilitada boolean,
	IN p_notif_alarma_protegido_habilitada boolean,
	IN p_notif_alarma_zona_vigilancia_habilitada boolean,
	IN p_notif_alarma_policia_habilitada boolean,
	IN p_dias_notif_policia_apagada integer,
	IN p_limite_alarmas_feed integer,
	IN p_intervalo_background_minutos integer,
	IN p_paises_feed_filtro text[] DEFAULT NULL)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE
	v_persona_id BIGINT;
	v_flag_es_policia BOOLEAN;
	v_dias_notif_policia_apagada INTEGER := p_dias_notif_policia_apagada;
BEGIN
	BEGIN

		SELECT
			persona_id
			,flag_es_policia
		INTO
			v_persona_id
			,v_flag_es_policia
		FROM
			personas
		WHERE
			user_id_thirdParty=p_user_id_thirdparty;

		if
			p_notif_alarma_policia_habilitada is false and p_dias_notif_policia_apagada is null
		then
			RAISE EXCEPTION 'Es obligatorio colocar el numero de dias de duracion del apagado de notificaciones para autoridad competente';
		end if;

		if
			v_flag_es_policia is false
		then
			v_dias_notif_policia_apagada := null;
		end if;

		UPDATE
			personas
		set
			notif_alarma_cercana_habilitada = p_notif_alarma_cercana_habilitada
			,notif_alarma_protegido_habilitada = p_notif_alarma_protegido_habilitada
			,notif_alarma_zona_vigilancia_habilitada = p_notif_alarma_zona_vigilancia_habilitada
			,notif_alarma_policia_habilitada = p_notif_alarma_policia_habilitada
			,dias_notif_policia_apagada = v_dias_notif_policia_apagada
			,fecha_act_configuracion_notif = now()
			,limite_alarmas_feed = p_limite_alarmas_feed
			,intervalo_background_minutos = p_intervalo_background_minutos
			,paises_feed_filtro = p_paises_feed_filtro
		WHERE
			persona_id=v_persona_id;

		EXCEPTION
			WHEN OTHERS THEN
				RAISE EXCEPTION '%', sqlerrm;

	END;
END
$BODY$;
