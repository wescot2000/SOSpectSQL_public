-- View: public.vw_cantidad_alarmas_zona

-- DROP VIEW public.vw_cantidad_alarmas_zona;

CREATE OR REPLACE VIEW public.vw_cantidad_alarmas_zona
 AS
 SELECT p.user_id_thirdparty,
    count(np.alarma_id) AS cantidad
   FROM personas p
     LEFT JOIN notificaciones_persona np ON np.persona_id = p.persona_id AND np.flag_enviado IS FALSE
  GROUP BY p.user_id_thirdparty;

ALTER TABLE public.vw_cantidad_alarmas_zona
    OWNER TO w4ll4c3;

