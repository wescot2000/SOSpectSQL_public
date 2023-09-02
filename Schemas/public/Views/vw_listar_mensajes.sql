-- View: public.vw_listar_mensajes

-- DROP VIEW public.vw_listar_mensajes;

CREATE OR REPLACE VIEW public.vw_listar_mensajes
 AS
 SELECT mu.mensaje_id,
    COALESCE(mu.asunto_traducido, mu.asunto) AS asunto,
    mu.estado,
    p.user_id_thirdparty,
    mu.fecha_mensaje,
    COALESCE(mu.idioma_post_traduccion, mu.idioma_origen) AS idioma_origen,
    COALESCE(mu.texto_traducido, mu.texto) AS texto
   FROM mensajes_a_usuarios mu
     JOIN personas p ON p.persona_id = mu.persona_id
  WHERE mu.estado IS TRUE AND mu.fecha_mensaje > (now() - '15 days'::interval)
UNION
 SELECT mu.mensaje_id,
    COALESCE(mu.asunto_traducido, mu.asunto) AS asunto,
    mu.estado,
    p.user_id_thirdparty,
    mu.fecha_mensaje,
    COALESCE(mu.idioma_post_traduccion, mu.idioma_origen) AS idioma_origen,
    COALESCE(mu.texto_traducido, mu.texto) AS texto
   FROM mensajes_a_usuarios mu
     JOIN personas p ON p.persona_id = mu.persona_id
  WHERE mu.estado IS FALSE AND mu.fecha_mensaje > (now() - '3 days'::interval);

ALTER TABLE public.vw_listar_mensajes
    OWNER TO w4ll4c3;

