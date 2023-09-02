-- View: public.vw_notificacion_alarmas

-- DROP VIEW public.vw_notificacion_alarmas;

CREATE OR REPLACE VIEW public.vw_notificacion_alarmas
 AS
 SELECT t.user_id_thirdparty,
    t.persona_id,
    t.latitud_alarma,
    t.longitud_alarma,
    t.user_id_creador_alarma,
    t.alarma_id,
    t.idioma AS idioma_destino,
    t.tipo_subscr_activa_usuario,
        CASE
            WHEN t.tipo_subscr_activa_usuario::text = 'Alarmas generadas por mi circulo social'::text THEN ((((((((('URGENTE! Tu PROTEGIDO '::text || t.login_usuario_protegido::text) || ' acaba de lanzar una alarma de tipo: '::text) || t.descripciontipoalarma::text) || ' a '::text) || ceiling(abs((t.latitud_alarma - t.latitud_usuario_notificar + (t.longitud_alarma - t.longitud_usuario_notificar) * 100::numeric) / 0.000900))) || ' metros de donde estas ubicado. Revisa la alarma para verificar de que se trata. Veracidad: '::text) || t.credibilidad_alarma) || ' por ciento.'::text))::character varying(250)
            WHEN t.tipo_subscr_activa_usuario::text = 'Zona de vigilancia adicional'::text THEN ((((((('IMPORTANTE! Alguien acaba de lanzar una alarma en una de las ZONAS de interés, alerta de tipo: '::text || t.descripciontipoalarma::text) || ' a '::text) || ceiling(abs((t.latitud_alarma - t.latitud_usuario_notificar + (t.longitud_alarma - t.longitud_usuario_notificar) * 100::numeric) / 0.000900))) || ' metros de la zona que deseas monitorear. Revisa la alarma para verificar de que se trata. Veracidad: '::text) || t.credibilidad_alarma) || ' por ciento.'::text))::character varying(250)
            ELSE ((((((('Alguien acaba de lanzar una alarma cerca de ti, alerta de tipo: '::text || t.descripciontipoalarma::text) || ' a '::text) || ceiling(abs((t.latitud_alarma - t.latitud_usuario_notificar + (t.longitud_alarma - t.longitud_usuario_notificar) * 100::numeric) / 0.000900))) || ' metros de donde estas ubicado. Revisa la alarma para verificar de que se trata. Veracidad: '::text) || t.credibilidad_alarma) || ' por ciento.'::text))::character varying(250)
        END AS txt_notif,
    t.tipoalarma_id
   FROM ( SELECT p.user_id_thirdparty,
            p.persona_id,
            alper.user_id_thirdparty AS user_id_creador_alarma,
            p.login AS login_usuario_notificar,
            alper.login AS login_usuario_protegido,
            al.latitud AS latitud_alarma,
            al.longitud AS longitud_alarma,
            u.latitud AS latitud_usuario_notificar,
            u.longitud AS longitud_usuario_notificar,
            ts.descripcion_tipo AS tipo_subscr_activa_usuario,
            s.fecha_activacion AS fecha_activacion_subscr,
            s.fecha_finalizacion AS fecha_finalizacion_subscr,
            ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
            'MYSELF'::text AS relacion_social,
            al.alarma_id,
            al.fecha_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id
           FROM ubicaciones u
             JOIN personas p ON p.persona_id = u.persona_id AND u."Tipo"::text = 'P'::text
             JOIN radio_alarmas ra ON p.radio_alarmas_id = ra.radio_alarmas_id
             LEFT JOIN subscripciones s ON s.persona_id = p.persona_id AND s.radio_alarmas_id IS NOT NULL AND now() >= s.fecha_activacion AND now() <= COALESCE(s.fecha_finalizacion, now())
             LEFT JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
             LEFT JOIN radio_alarmas ra_susc ON ra_susc.radio_alarmas_id = s.radio_alarmas_id
             JOIN alarmas al ON u.latitud >= (al.latitud -
                CASE
                    WHEN ra_susc.radio_alarmas_id IS NOT NULL THEN ra_susc.radio_double
                    ELSE ra.radio_double
                END) AND u.latitud <= (al.latitud +
                CASE
                    WHEN ra_susc.radio_alarmas_id IS NOT NULL THEN ra_susc.radio_double
                    ELSE ra.radio_double
                END) AND u.longitud >= (al.longitud -
                CASE
                    WHEN ra_susc.radio_alarmas_id IS NOT NULL THEN ra_susc.radio_double
                    ELSE ra.radio_double
                END) AND u.longitud <= (al.longitud +
                CASE
                    WHEN ra_susc.radio_alarmas_id IS NOT NULL THEN ra_susc.radio_double
                    ELSE ra.radio_double
                END)
             JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
             JOIN personas alper ON alper.persona_id = al.persona_id
             JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
             LEFT JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND p.persona_id = rp.id_persona_protector AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now()) AND (rp.fecha_suspension IS NULL AND rp.fecha_reactivacion IS NULL OR rp.fecha_suspension IS NULL AND rp.fecha_reactivacion <= now() OR rp.fecha_reactivacion IS NULL AND rp.fecha_suspension >= now() OR now() < rp.fecha_suspension OR now() > rp.fecha_reactivacion)
          WHERE al.estado_alarma IS NULL AND (al.tipoalarma_id <> ALL (ARRAY[4, 5, 6])) AND rp.id_rel_protegido IS NULL AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
        UNION
         SELECT p.user_id_thirdparty,
            p.persona_id,
            alper.user_id_thirdparty AS user_id_creador_alarma,
            p.login AS login_usuario_notificar,
            alper.login AS login_usuario_protegido,
            al.latitud AS latitud_alarma,
            al.longitud AS longitud_alarma,
            u.latitud AS latitud_usuario_notificar,
            u.longitud AS longitud_usuario_notificar,
            ts.descripcion_tipo AS tipo_subscr_activa_usuario,
            s.fecha_activacion AS fecha_activacion_subscr,
            s.fecha_finalizacion AS fecha_finalizacion_subscr,
            ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
            'SURVEY_ZONE'::text AS relacion_social,
            al.alarma_id,
            al.fecha_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id
           FROM alarmas al
             JOIN ubicaciones u ON u.latitud >= (al.latitud - 0.001800) AND u.latitud <= (al.latitud + 0.001800) AND u.longitud >= (al.longitud - 0.001800) AND u.longitud <= (al.longitud + 0.001800) AND u."Tipo"::text = 'S'::text
             JOIN personas p ON p.persona_id = u.persona_id
             JOIN subscripciones s ON u.ubicacion_id = s.ubicacion_id AND u."Tipo"::text = 'S'::text AND now() >= s.fecha_activacion AND now() <= COALESCE(s.fecha_finalizacion, now())
             JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
             JOIN personas alper ON alper.persona_id = al.persona_id
             JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
             JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
             LEFT JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now()) AND (rp.fecha_suspension IS NULL AND rp.fecha_reactivacion IS NULL OR rp.fecha_suspension IS NULL AND rp.fecha_reactivacion <= now() OR rp.fecha_reactivacion IS NULL AND rp.fecha_suspension >= now() OR now() < rp.fecha_suspension OR now() > rp.fecha_reactivacion)
          WHERE al.estado_alarma IS NULL AND (al.tipoalarma_id <> ALL (ARRAY[4, 5, 6])) AND rp.id_rel_protegido IS NULL AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
        UNION
         SELECT p.user_id_thirdparty,
            p.persona_id,
            alper.user_id_thirdparty AS user_id_creador_alarma,
            p.login AS login_usuario_notificar,
            alper.login AS login_usuario_protegido,
            al.latitud AS latitud_alarma,
            al.longitud AS longitud_alarma,
            u.latitud AS latitud_usuario_notificar,
            u.longitud AS longitud_usuario_notificar,
            NULL::character varying AS tipo_subscr_activa_usuario,
            NULL::timestamp with time zone AS fecha_activacion_subscr,
            NULL::timestamp with time zone AS fecha_finalizacion_subscr,
            ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
            'MYSELF'::text AS relacion_social,
            al.alarma_id,
            al.fecha_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id
           FROM alarmas al
             JOIN ubicaciones u ON u.latitud >= (al.latitud - 0.090000) AND u.latitud <= (al.latitud + 0.090000) AND u.longitud >= (al.longitud - 0.090000) AND u.longitud <= (al.longitud + 0.090000) AND u."Tipo"::text = 'P'::text
             JOIN personas p ON p.persona_id = u.persona_id
             JOIN personas alper ON alper.persona_id = al.persona_id
             JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
             JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
             LEFT JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now()) AND (rp.fecha_suspension IS NULL AND rp.fecha_reactivacion IS NULL OR rp.fecha_suspension IS NULL AND rp.fecha_reactivacion <= now() OR rp.fecha_reactivacion IS NULL AND rp.fecha_suspension >= now() OR now() < rp.fecha_suspension OR now() > rp.fecha_reactivacion)
          WHERE al.estado_alarma IS NULL AND (al.tipoalarma_id = ANY (ARRAY[4, 5])) AND rp.id_rel_protegido IS NULL AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
        UNION
         SELECT p.user_id_thirdparty,
            p.persona_id,
            alper.user_id_thirdparty AS user_id_creador_alarma,
            p.login AS login_usuario_notificar,
            alper.login AS login_usuario_protegido,
            al.latitud AS latitud_alarma,
            al.longitud AS longitud_alarma,
            u.latitud AS latitud_usuario_notificar,
            u.longitud AS longitud_usuario_notificar,
            NULL::character varying AS tipo_subscr_activa_usuario,
            NULL::timestamp with time zone AS fecha_activacion_subscr,
            NULL::timestamp with time zone AS fecha_finalizacion_subscr,
            ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
            'MYSELF'::text AS relacion_social,
            al.alarma_id,
            al.fecha_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id
           FROM alarmas al
             JOIN ubicaciones u ON u.latitud >= (al.latitud - 0.009000) AND u.latitud <= (al.latitud + 0.009000) AND u.longitud >= (al.longitud - 0.009000) AND u.longitud <= (al.longitud + 0.009000) AND u."Tipo"::text = 'P'::text
             JOIN personas p ON p.persona_id = u.persona_id
             JOIN personas alper ON alper.persona_id = al.persona_id
             JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
             JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
             LEFT JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now()) AND (rp.fecha_suspension IS NULL AND rp.fecha_reactivacion IS NULL OR rp.fecha_suspension IS NULL AND rp.fecha_reactivacion <= now() OR rp.fecha_reactivacion IS NULL AND rp.fecha_suspension >= now() OR now() < rp.fecha_suspension OR now() > rp.fecha_reactivacion)
          WHERE al.estado_alarma IS NULL AND al.tipoalarma_id = 6 AND rp.id_rel_protegido IS NULL AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
        UNION
         SELECT p.user_id_thirdparty,
            p.persona_id,
            alper.user_id_thirdparty AS user_id_creador_alarma,
            p.login AS login_usuario_notificar,
            alper.login AS login_usuario_protegido,
            al.latitud AS latitud_alarma,
            al.longitud AS longitud_alarma,
            u.latitud AS latitud_usuario_notificar,
            u.longitud AS longitud_usuario_notificar,
            NULL::character varying AS tipo_subscr_activa_usuario,
            NULL::timestamp with time zone AS fecha_activacion_subscr,
            NULL::timestamp with time zone AS fecha_finalizacion_subscr,
            ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
            'MYSELF'::text AS relacion_social,
            al.alarma_id,
            al.fecha_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id
           FROM alarmas al
             JOIN ubicaciones u ON u.latitud >= (al.latitud - 9.000000) AND u.latitud <= (al.latitud + 9.000000) AND u.longitud >= (al.longitud - 9.000000) AND u.longitud <= (al.longitud + 9.000000) AND u."Tipo"::text = 'P'::text
             JOIN personas p ON p.persona_id = u.persona_id
             JOIN personas alper ON alper.persona_id = al.persona_id
             JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
             JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
             LEFT JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now()) AND (rp.fecha_suspension IS NULL AND rp.fecha_reactivacion IS NULL OR rp.fecha_suspension IS NULL AND rp.fecha_reactivacion <= now() OR rp.fecha_reactivacion IS NULL AND rp.fecha_suspension >= now() OR now() < rp.fecha_suspension OR now() > rp.fecha_reactivacion)
          WHERE al.estado_alarma IS NULL AND rp.id_rel_protegido IS NULL AND p.user_id_thirdparty::text = alper.user_id_thirdparty::text
        UNION
         SELECT p.user_id_thirdparty,
            p.persona_id,
            alper.user_id_thirdparty AS user_id_creador_alarma,
            p.login AS login_usuario_notificar,
            alper.login AS login_usuario_protegido,
            al.latitud AS latitud_alarma,
            al.longitud AS longitud_alarma,
            u.latitud AS latitud_usuario_notificar,
            u.longitud AS longitud_usuario_notificar,
            ts.descripcion_tipo AS tipo_subscr_activa_usuario,
            s.fecha_activacion AS fecha_activacion_subscr,
            s.fecha_finalizacion AS fecha_finalizacion_subscr,
            ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
            tr.descripciontiporel AS relacion_social,
            al.alarma_id,
            al.fecha_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id
           FROM alarmas al
             JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now()) AND (rp.fecha_suspension IS NULL AND rp.fecha_reactivacion IS NULL OR rp.fecha_suspension IS NULL AND rp.fecha_reactivacion <= now() OR rp.fecha_reactivacion IS NULL AND rp.fecha_suspension >= now() OR now() < rp.fecha_suspension OR now() > rp.fecha_reactivacion)
             JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
             JOIN tiporelacion tr ON tr.tiporelacion_id = rp.tiporelacion_id
             JOIN personas alper ON alper.persona_id = rp.id_persona_protegida
             JOIN subscripciones s ON rp.id_rel_protegido = s.id_rel_protegido AND al.fecha_alarma >= s.fecha_activacion AND al.fecha_alarma <= COALESCE(s.fecha_finalizacion, now())
             JOIN personas p ON p.persona_id = s.persona_id
             JOIN radio_alarmas ra ON p.radio_alarmas_id = ra.radio_alarmas_id
             LEFT JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
             JOIN ubicaciones u ON u.persona_id = p.persona_id AND u."Tipo"::text = 'P'::text
             JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
          WHERE al.estado_alarma IS NULL AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text) t;

ALTER TABLE public.vw_notificacion_alarmas
    OWNER TO w4ll4c3;

