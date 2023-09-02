-- View: public.vw_leer_mensaje

-- DROP VIEW public.vw_leer_mensaje;

CREATE OR REPLACE VIEW public.vw_leer_mensaje
 AS
 SELECT mu.mensaje_id,
    COALESCE(mu.asunto_traducido, mu.asunto) AS asunto,
    mu.estado,
    COALESCE(mu.texto_traducido, mu.texto) AS texto,
    p.user_id_thirdparty,
    p.login AS para,
    'SOSpect'::text AS remitente,
    mu.fecha_mensaje,
    COALESCE(mu.idioma_post_traduccion, mu.idioma_origen) AS idioma_origen,
    mu.alarma_id
   FROM mensajes_a_usuarios mu
     JOIN personas p ON p.persona_id = mu.persona_id
  ORDER BY mu.fecha_mensaje DESC;

ALTER TABLE public.vw_leer_mensaje
    OWNER TO w4ll4c3;

