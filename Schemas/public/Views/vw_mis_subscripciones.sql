-- View: public.vw_mis_subscripciones

-- DROP VIEW public.vw_mis_subscripciones;

CREATE OR REPLACE VIEW public.vw_mis_subscripciones
 AS
 WITH ranked_subscriptions AS (
         SELECT s.subscripcion_id,
            p.user_id_thirdparty,
            ts.descripcion_tipo,
                CASE
                    WHEN rp.id_rel_protegido IS NOT NULL THEN (('Usuario protegido: '::text || pprot.login::text))::character varying(1200)
                    WHEN ra.radio_alarmas_id IS NOT NULL THEN (('Radio ampliado en subscripcion: '::text || ra.radio_mts))::character varying(1200)
                    WHEN u.ubicacion_id IS NOT NULL THEN (((('Zona de vigilancia adquirida (Consulta el punto en google maps si te resulta desconocida): '::text || u.latitud) || ','::text) || u.longitud))::character varying(1200)
                    ELSE NULL::character varying
                END AS descripcion,
            s.fecha_finalizacion,
            s.poderes_consumidos AS poderes_renovacion,
                CASE
                    WHEN now() > s.fecha_finalizacion THEN true
                    ELSE false
                END AS flag_subscr_vencida,
            COALESCE(s.observaciones, 'Ninguna Observacion'::character varying) AS observ_subscripcion,
                CASE
                    WHEN s.observaciones IS NOT NULL THEN false
                    WHEN (EXISTS ( SELECT 1
                       FROM subscripciones active_sub
                         LEFT JOIN relacion_protegidos rpt ON rpt.id_rel_protegido = active_sub.id_rel_protegido
                         LEFT JOIN personas pprote ON pprote.persona_id = rpt.id_persona_protegida
                      WHERE active_sub.persona_id = s.persona_id AND active_sub.tipo_subscr_id = s.tipo_subscr_id AND active_sub.fecha_finalizacion > now() AND pprot.login::text = pprote.login::text)) THEN false
                    ELSE true
                END AS flag_renovable,
                CASE
                    WHEN s.observaciones IS NOT NULL THEN 'No puede renovarse debido a que fue cancelada, requiere subscripción nueva'::character varying(80)
                    WHEN s.fecha_finalizacion > now() THEN 'Subscripcion vigente'::character varying(80)
                    WHEN (EXISTS ( SELECT 1
                       FROM subscripciones active_sub
                         LEFT JOIN relacion_protegidos rpt ON rpt.id_rel_protegido = active_sub.id_rel_protegido
                         LEFT JOIN personas pprote ON pprote.persona_id = rpt.id_persona_protegida
                      WHERE active_sub.persona_id = s.persona_id AND active_sub.tipo_subscr_id = s.tipo_subscr_id AND active_sub.fecha_finalizacion > now() AND pprot.login::text = pprote.login::text)) THEN 'Actualmente activo en otra suscripcion'::character varying(80)
                    ELSE 'Renovable'::character varying(80)
                END AS texto_renovable,
            row_number() OVER (PARTITION BY p.user_id_thirdparty, (
                CASE
                    WHEN s.fecha_finalizacion < now() THEN 1
                    ELSE 2
                END) ORDER BY s.fecha_finalizacion DESC) AS rn
           FROM subscripciones s
             JOIN personas p ON p.persona_id = s.persona_id
             JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
             LEFT JOIN relacion_protegidos rp ON rp.id_rel_protegido = s.id_rel_protegido
             LEFT JOIN personas pprot ON pprot.persona_id = rp.id_persona_protegida
             LEFT JOIN radio_alarmas ra ON ra.radio_alarmas_id = s.radio_alarmas_id
             LEFT JOIN ubicaciones u ON u.ubicacion_id = s.ubicacion_id AND u."Tipo"::text = 'S'::text
        )
 SELECT rk.subscripcion_id,
    rk.user_id_thirdparty,
    rk.descripcion_tipo,
    rk.descripcion,
    rk.fecha_finalizacion,
    rk.poderes_renovacion,
    rk.flag_subscr_vencida,
    rk.observ_subscripcion,
    rk.flag_renovable,
    rk.texto_renovable,
    rk.rn
   FROM ranked_subscriptions rk
  WHERE rk.fecha_finalizacion > now() OR rk.fecha_finalizacion < now() AND rk.rn <= 3
  ORDER BY rk.fecha_finalizacion DESC;

ALTER TABLE public.vw_mis_subscripciones
    OWNER TO w4ll4c3;

