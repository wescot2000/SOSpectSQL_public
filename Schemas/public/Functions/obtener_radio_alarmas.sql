-- FUNCTION: public.obtener_radio_alarmas(character varying)

-- DROP FUNCTION IF EXISTS public.obtener_radio_alarmas(character varying);

CREATE OR REPLACE FUNCTION public.obtener_radio_alarmas(
	p_user_id_thirdparty character varying)
    RETURNS TABLE(radio_alarmas_id integer, radio_mts integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

BEGIN
  RETURN QUERY
  SELECT
    ral.radio_alarmas_id, ral.radio_mts
  FROM
    radio_alarmas ral
  WHERE
    ral.radio_mts > (
      SELECT
        COALESCE(asub.radio_mts, a.radio_mts) radio
      FROM
        personas p
        INNER JOIN radio_alarmas a ON (a.radio_alarmas_id = p.radio_alarmas_id)
        LEFT OUTER JOIN subscripciones s ON (
          s.persona_id = p.persona_id AND
          now() BETWEEN s.fecha_activacion AND COALESCE(s.fecha_finalizacion, now()) AND
          s.tipo_subscr_id = 2
        )
        LEFT OUTER JOIN radio_alarmas asub ON (asub.radio_alarmas_id = s.radio_alarmas_id)
      WHERE
        p.user_id_thirdparty = p_user_id_thirdparty
    )
  ORDER BY
    radio_mts ASC;
END;
$BODY$;

ALTER FUNCTION public.obtener_radio_alarmas(character varying)
    OWNER TO w4ll4c3;
