-- View: public.vw_notificacion_alarmas
-- Vista para feed Siguiendo con filtro de 90 minutos y radios parametrizados
-- Fecha: 2026-01-05 (Agregado soporte para alarmas promocionales)
-- ACTUALIZADO: 2026-01-29 - Usar texto_push_personalizado para notificaciones push en lugar de descripcionalarma

-- DROP VIEW IF EXISTS public.vw_notificacion_alarmas;

CREATE OR REPLACE VIEW public.vw_notificacion_alarmas
 AS
   WITH
   -- ========================================
   -- CTE 1: Datos de subscripciones promocionales CON texto_push_personalizado
   -- ACTUALIZADO 2026-01-29: Se agrega texto_push_personalizado para notificaciones push
   -- ========================================
   DatosPromocionalesSinDescripcion AS (
       SELECT
           s.alarma_id,
           e.url_logo,
           s.radio_metros,
           s.radio_alarmas_id,
           s.fecha_activacion,
           s.fecha_finalizacion,
           s.tipo_subscr_id,
           ts.descripcion_tipo,
           COALESCE(ra_promo.radio_mts, s.radio_metros) AS radio_actual,
           s.texto_push_personalizado  -- AGREGADO 2026-01-29: Texto de notificación push
       FROM subscripciones s
       JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
       LEFT JOIN emprendimientos e ON s.id_emprendimiento = e.id_emprendimiento
           AND e.fecha_fin IS NULL
       LEFT JOIN radio_alarmas ra_promo ON ra_promo.radio_alarmas_id = s.radio_alarmas_id
       WHERE s.tipo_subscr_id = 4  -- Solo subscripciones publicitarias
         AND now() >= s.fecha_activacion
         AND now() <= COALESCE(s.fecha_finalizacion, now())
   ),
   -- ========================================
   -- CTE 2: SOLO descripcionalarma de la alarma promocional (un registro por alarma)
   -- NOTA: Este CTE se mantiene para compatibilidad pero ya no se usa para txt_notif
   -- ========================================
   DescripcionPromocion AS (
       SELECT
           da.alarma_id,
           MAX(da.descripcionalarma) AS descripcionalarma  -- GROUP BY garantiza un solo valor
       FROM descripcionesalarmas da
       JOIN alarmas al ON al.alarma_id = da.alarma_id
       JOIN subscripciones s ON s.alarma_id = al.alarma_id
           AND s.persona_id = al.persona_id
           AND s.tipo_subscr_id = 4
       WHERE al.tipoalarma_id = 13  -- Solo alarmas promocionales
       GROUP BY da.alarma_id
   ),
   -- ========================================
   -- CTE 3: Datos promocionales completos CON texto_push_personalizado
   -- ACTUALIZADO 2026-01-29: Se agrega texto_push_personalizado para notificaciones
   -- ========================================
   DatosPromocionalesCompletos AS (
       SELECT
           dp.alarma_id,
           dp.url_logo,
           dp.radio_metros,
           dp.radio_alarmas_id,
           dp.fecha_activacion,
           dp.fecha_finalizacion,
           dp.tipo_subscr_id,
           dp.descripcion_tipo,
           dp.radio_actual,
           desc_promo.descripcionalarma,  -- Se mantiene para compatibilidad
           dp.texto_push_personalizado    -- AGREGADO 2026-01-29: Texto de notificación push
       FROM DatosPromocionalesSinDescripcion dp
       CROSS JOIN DescripcionPromocion desc_promo
       WHERE dp.alarma_id = desc_promo.alarma_id  -- JOIN para asegurar que sea la misma alarma
   ),
   -- ========================================
   -- CTE 4: Primera foto de cada alarma (para notificaciones)
   -- ========================================
   PrimeraFotoAlarma AS (
       SELECT DISTINCT ON (da.alarma_id)
           da.alarma_id,
           f.url_foto AS primera_foto_url
       FROM descripcionesalarmas da
       JOIN fotos_descripciones_alarmas f ON f.iddescripcion = da.iddescripcion
       WHERE f.estado = 'A' AND f.es_video = false  -- Solo fotos activas, no videos
       ORDER BY da.alarma_id, f.orden ASC, f.fecha_subida ASC
   ),
   Prioridades AS
      (
        -- UNION 1: Alarmas cercanas (radio usuario, excluye tipos 4,5,6,13)
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
            'MYSELF'::text AS relacion_social,
            al.alarma_id,
            al.fecha_alarma,
            al.estado_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id,
            cast(3 as integer) AS prioridad,
            coalesce(alper.flag_red_confianza, cast(FALSE as boolean)) as flag_red_confianza,
            dis.registrationid,
            ra.radio_mts AS radio_alarmas_mts_actual,
            COALESCE(ta.radio_interes_metros, ra.radio_mts) AS radio_interes_metros,
            ta.minutos_vigencia,
            NULL::text AS descripcion_personalizada,  -- Nuevo campo para texto personalizado
            NULL::character varying AS url_logo  -- URL del logo (solo para promocionales)
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
             LEFT JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND p.persona_id = rp.id_persona_protector AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now())
          WHERE
            ((
                al.estado_alarma IS NULL
            )
            OR
            (
                al.estado_alarma IS NOT NULL AND al.fecha_alarma > NOW() - interval '90 minutes'
            ))
            AND p.notif_alarma_cercana_habilitada IS TRUE
            AND (al.tipoalarma_id <> ALL (ARRAY[4, 5, 6, 13]))  -- Excluir mascota/persona perdida, disturbios Y promocionales
            AND rp.id_rel_protegido IS NULL
            AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
            AND (
                  (p.flag_es_policia IS TRUE AND p.notif_alarma_policia_habilitada IS TRUE)
                  OR p.flag_es_policia IS NOT TRUE
               )
        UNION
        -- UNION 2: Zona de vigilancia (300m fijo)
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
            al.estado_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id,
            cast(2 as integer) AS prioridad,
            coalesce(alper.flag_red_confianza, cast(FALSE as boolean)) as flag_red_confianza,
            dis.registrationid,
            ra.radio_mts AS radio_alarmas_mts_actual,
            300 AS radio_interes_metros,  -- Radio fijo de 300m para zonas de vigilancia
            ta.minutos_vigencia,
            NULL::text AS descripcion_personalizada,
            NULL::character varying AS url_logo
           FROM alarmas al
             JOIN ubicaciones u ON u.latitud >= (al.latitud - 0.002727) AND u.latitud <= (al.latitud + 0.002727) AND u.longitud >= (al.longitud - 0.002727) AND u.longitud <= (al.longitud + 0.002727) AND u."Tipo"::text = 'S'::text
             JOIN personas p ON p.persona_id = u.persona_id
             JOIN radio_alarmas ra ON p.radio_alarmas_id = ra.radio_alarmas_id
             JOIN subscripciones s ON u.ubicacion_id = s.ubicacion_id AND u."Tipo"::text = 'S'::text AND now() >= s.fecha_activacion AND now() <= COALESCE(s.fecha_finalizacion, now())
             JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
             JOIN personas alper ON alper.persona_id = al.persona_id
             JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
             JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
             LEFT JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now())
          WHERE
            (al.estado_alarma IS NULL OR (al.estado_alarma IS NOT NULL AND al.fecha_alarma > NOW() - interval '90 minutes'))
            AND p.notif_alarma_zona_vigilancia_habilitada IS TRUE
            AND (al.tipoalarma_id <> ALL (ARRAY[4, 5, 6, 13]))  -- Excluir tipos especiales Y promocionales
            AND rp.id_rel_protegido IS NULL
            AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
        UNION
        -- UNION 3: Mascota/Persona perdida (radio 10km)
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
            al.estado_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id,
            cast(3 as integer) AS prioridad,
            coalesce(alper.flag_red_confianza, cast(FALSE as boolean)) as flag_red_confianza,
            dis.registrationid,
            ra.radio_mts AS radio_alarmas_mts_actual,
            ta.radio_interes_metros AS radio_interes_metros,  -- Usa radio del tipo (10km)
            ta.minutos_vigencia,
            NULL::text AS descripcion_personalizada,
            NULL::character varying AS url_logo
           FROM alarmas al
             JOIN ubicaciones u ON u.latitud >= (al.latitud - 0.090000) AND u.latitud <= (al.latitud + 0.090000) AND u.longitud >= (al.longitud - 0.090000) AND u.longitud <= (al.longitud + 0.090000) AND u."Tipo"::text = 'P'::text
             JOIN personas p ON p.persona_id = u.persona_id
             JOIN radio_alarmas ra ON p.radio_alarmas_id = ra.radio_alarmas_id
             JOIN personas alper ON alper.persona_id = al.persona_id
             JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
             JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
             LEFT JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now())
          WHERE
            (al.estado_alarma IS NULL OR (al.estado_alarma IS NOT NULL AND al.fecha_alarma > NOW() - interval '90 minutes'))
            AND p.notif_alarma_cercana_habilitada IS TRUE
            AND (al.tipoalarma_id = ANY (ARRAY[4, 5]))  -- Solo persona/mascota perdida
            AND rp.id_rel_protegido IS NULL
            AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
            AND (
                  (p.flag_es_policia IS TRUE AND p.notif_alarma_policia_habilitada IS TRUE)
                  OR p.flag_es_policia IS NOT TRUE
               )
        UNION
        -- UNION 4: Disturbios (radio 2km)
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
            al.estado_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id,
            cast(3 as integer) AS prioridad,
            coalesce(alper.flag_red_confianza, cast(FALSE as boolean)) as flag_red_confianza,
            dis.registrationid,
            ra.radio_mts AS radio_alarmas_mts_actual,
            ta.radio_interes_metros AS radio_interes_metros,  -- Usa radio del tipo (2km)
            ta.minutos_vigencia,
            NULL::text AS descripcion_personalizada,
            NULL::character varying AS url_logo
           FROM alarmas al
             JOIN ubicaciones u ON u.latitud >= (al.latitud - 0.018000) AND u.latitud <= (al.latitud + 0.018000) AND u.longitud >= (al.longitud - 0.018000) AND u.longitud <= (al.longitud + 0.018000) AND u."Tipo"::text = 'P'::text
             JOIN personas p ON p.persona_id = u.persona_id
             JOIN radio_alarmas ra ON p.radio_alarmas_id = ra.radio_alarmas_id
             JOIN personas alper ON alper.persona_id = al.persona_id
             JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
             JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
             LEFT JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now())
          WHERE
            (al.estado_alarma IS NULL OR (al.estado_alarma IS NOT NULL AND al.fecha_alarma > NOW() - interval '90 minutes'))
            AND p.notif_alarma_cercana_habilitada IS TRUE
            AND al.tipoalarma_id = 6  -- Solo disturbios
            AND rp.id_rel_protegido IS NULL
            AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
            AND (
                  (p.flag_es_policia IS TRUE AND p.notif_alarma_policia_habilitada IS TRUE)
                  OR p.flag_es_policia IS NOT TRUE
               )
        UNION
        -- UNION 5: Alarmas propias del usuario
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
            al.estado_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id,
            cast(3 as integer) AS prioridad,
            coalesce(alper.flag_red_confianza, cast(FALSE as boolean)) as flag_red_confianza,
            dis.registrationid,
            ra.radio_mts AS radio_alarmas_mts_actual,
            COALESCE(ta.radio_interes_metros, ra.radio_mts) AS radio_interes_metros,
            ta.minutos_vigencia,
            NULL::text AS descripcion_personalizada,
            NULL::character varying AS url_logo
           FROM alarmas al
             JOIN ubicaciones u ON u.latitud >= (al.latitud - 0.090000) AND u.latitud <= (al.latitud + 0.090000) AND u.longitud >= (al.longitud - 0.090000) AND u.longitud <= (al.longitud + 0.090000) AND u."Tipo"::text = 'P'::text
             JOIN personas p ON p.persona_id = u.persona_id
             JOIN radio_alarmas ra ON p.radio_alarmas_id = ra.radio_alarmas_id
             JOIN personas alper ON alper.persona_id = al.persona_id
             JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
             JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
             LEFT JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now())
          WHERE
            (al.estado_alarma IS NULL OR (al.estado_alarma IS NOT NULL AND al.fecha_alarma > NOW() - interval '90 minutes'))
            AND p.notif_alarma_cercana_habilitada IS TRUE
            AND rp.id_rel_protegido IS NULL
            AND p.user_id_thirdparty::text = alper.user_id_thirdparty::text  -- Solo alarmas del mismo usuario
            AND al.tipoalarma_id <> 13  -- Excluir promocionales de notificaciones propias
          AND (
                  (p.flag_es_policia IS TRUE AND p.notif_alarma_policia_habilitada IS TRUE)
                  OR p.flag_es_policia IS NOT TRUE
               )
        UNION
        -- UNION 6: Protegidos (círculo social)
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
            al.estado_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id,
            cast(1 as integer) AS prioridad,
            coalesce(alper.flag_red_confianza, cast(FALSE as boolean)) as flag_red_confianza,
            dis.registrationid,
            ra.radio_mts AS radio_alarmas_mts_actual,
            COALESCE(ta.radio_interes_metros, ra.radio_mts) AS radio_interes_metros,
            ta.minutos_vigencia,
            NULL::text AS descripcion_personalizada,
            NULL::character varying AS url_logo
           FROM alarmas al
             JOIN relacion_protegidos rp ON al.persona_id = rp.id_persona_protegida AND now() >= rp.fecha_activacion AND now() <= COALESCE(rp.fecha_finalizacion, now())
             JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
             JOIN tiporelacion tr ON tr.tiporelacion_id = rp.tiporelacion_id
             JOIN personas alper ON alper.persona_id = rp.id_persona_protegida
             JOIN subscripciones s ON rp.id_rel_protegido = s.id_rel_protegido AND al.fecha_alarma >= s.fecha_activacion AND al.fecha_alarma <= COALESCE(s.fecha_finalizacion, now())
             JOIN personas p ON p.persona_id = s.persona_id
             JOIN radio_alarmas ra ON p.radio_alarmas_id = ra.radio_alarmas_id
             LEFT JOIN tiposubscripcion ts ON ts.tipo_subscr_id = s.tipo_subscr_id
             JOIN ubicaciones u ON u.persona_id = p.persona_id AND u."Tipo"::text = 'P'::text
             JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
          WHERE
            (al.estado_alarma IS NULL OR (al.estado_alarma IS NOT NULL AND al.fecha_alarma > NOW() - interval '90 minutes'))
            AND p.notif_alarma_protegido_habilitada IS TRUE
            AND p.user_id_thirdparty::text <> alper.user_id_thirdparty::text
            AND al.tipoalarma_id <> 13  -- Excluir promocionales de notificaciones a protegidos
        UNION
        -- ========================================
        -- NUEVO UNION 7: ALARMAS PROMOCIONALES
        -- ========================================
        -- Las alarmas promocionales tienen características especiales:
        -- - tipoalarma_id = 13
        -- - Usan radio personalizado guardado en subscripciones.radio_alarmas_id
        -- - ACTUALIZADO 2026-01-29: El texto de notificación viene de subscripciones.texto_push_personalizado
        -- - No tienen minutos_vigencia (se manejan por fecha_finalizacion de subscripción)
        -- - INCLUYE al creador (sin exclusión) para que reciba su propia notificación
        -- ========================================
         SELECT p.user_id_thirdparty,
            p.persona_id,
            alper.user_id_thirdparty AS user_id_creador_alarma,
            p.login AS login_usuario_notificar,
            alper.login AS login_usuario_protegido,
            al.latitud AS latitud_alarma,
            al.longitud AS longitud_alarma,
            u.latitud AS latitud_usuario_notificar,
            u.longitud AS longitud_usuario_notificar,
            promo_data.descripcion_tipo AS tipo_subscr_activa_usuario,
            promo_data.fecha_activacion AS fecha_activacion_subscr,
            promo_data.fecha_finalizacion AS fecha_finalizacion_subscr,
            ceiling(abs((al.latitud - u.latitud + (al.longitud - u.longitud) * 100::numeric) / 0.000900)) AS distancia_en_metros,
            'PROMOTIONAL'::text AS relacion_social,
            al.alarma_id,
            al.fecha_alarma,
            al.estado_alarma,
            ta.descripciontipoalarma,
            al.calificacion_alarma AS credibilidad_alarma,
            EXTRACT(epoch FROM now() - al.fecha_alarma) / 60::numeric AS minutos_desde_reportada,
            dis.idioma,
            ta.tipoalarma_id,
            cast(1 as integer) AS prioridad,  -- Prioridad 1 (máxima) - Las promociones son PAGADAS y tienen preferencia
            FALSE as flag_red_confianza,      -- Promocionales no son red de confianza
            dis.registrationid,
            COALESCE(promo_data.radio_actual, p_ra.radio_mts) AS radio_alarmas_mts_actual,
            promo_data.radio_actual AS radio_interes_metros,  -- Radio de la subscripción promocional
            NULL::smallint AS minutos_vigencia,          -- NULL porque usa fecha_finalizacion
            promo_data.texto_push_personalizado AS descripcion_personalizada,  -- ACTUALIZADO 2026-01-29: Usar texto de notificación push
            promo_data.url_logo  -- URL del logo del emprendimiento desde emprendimientos.url_logo (18-01-2026)
           FROM alarmas al
             -- JOIN con CTE DatosPromocionalesCompletos (contiene descripcionalarma para TODOS)
             JOIN DatosPromocionalesCompletos promo_data ON promo_data.alarma_id = al.alarma_id
             -- Calcular radio en grados para la búsqueda espacial
             CROSS JOIN LATERAL (SELECT promo_data.radio_actual / 111000.0 AS radio_degrees) rd
             -- Join con ubicaciones de usuarios dentro del radio de la promoción
             JOIN ubicaciones u ON u.latitud >= (al.latitud - rd.radio_degrees)
                AND u.latitud <= (al.latitud + rd.radio_degrees)
                AND u.longitud >= (al.longitud - rd.radio_degrees)
                AND u.longitud <= (al.longitud + rd.radio_degrees)
                AND u."Tipo"::text = 'P'::text
             JOIN personas p ON p.persona_id = u.persona_id
             -- LEFT JOIN para el radio actual del usuario (puede ser NULL si no tiene suscripción activa)
             LEFT JOIN radio_alarmas p_ra ON p_ra.radio_alarmas_id = p.radio_alarmas_id
             JOIN personas alper ON alper.persona_id = al.persona_id
             JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
             JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
          WHERE
            al.tipoalarma_id = 13  -- Solo alarmas promocionales
            AND p.notif_alarma_cercana_habilitada IS TRUE
            -- NOTA: No se excluye al creador - recibirá su propia notificación gratis
          ),
   FotosAlarma AS (
      SELECT
         f.foto_id,
         da.alarma_id,
         f.url_foto,
         f.thumbnail_url,
         f.nombre_archivo_original,
         f.tipo_mime,
         f.es_video,
         f.tamano_bytes,
         f.ancho_pixels,
         f.alto_pixels,
         f.orden,
         f.fecha_subida,
         ROW_NUMBER() OVER (PARTITION BY da.alarma_id ORDER BY da.fechadescripcion ASC, f.orden ASC, f.fecha_subida ASC) AS rn
      FROM fotos_descripciones_alarmas f
      JOIN descripcionesalarmas da ON f.iddescripcion = da.iddescripcion
      WHERE f.estado = 'A'
   )
 SELECT t.user_id_thirdparty,
    t.persona_id,
    t.user_id_creador_alarma,
    CASE
        WHEN LENGTH(t.user_id_creador_alarma) > 7 THEN
            SUBSTRING(t.user_id_creador_alarma, 1, 3) || '-' ||
            SUBSTRING(t.user_id_creador_alarma, LENGTH(t.user_id_creador_alarma) - 3, 4)
        ELSE t.user_id_creador_alarma
    END AS usuario_anonimizado,
    t.login_usuario_notificar,
    t.latitud_alarma,
    t.longitud_alarma,
    t.latitud_usuario_notificar AS latitud_entrada,
    t.longitud_usuario_notificar AS longitud_entrada,
    t.tipo_subscr_activa_usuario,
    t.fecha_activacion_subscr,
    t.fecha_finalizacion_subscr,
    t.distancia_en_metros,
    t.alarma_id,
    t.fecha_alarma,
    t.descripciontipoalarma,
    t.tipoalarma_id,
    60::smallint AS TiempoRefrescoUbicacion,
    CASE
        WHEN t.user_id_thirdparty::text = t.user_id_creador_alarma::text THEN true
        ELSE false
    END AS flag_propietario_alarma,
    t.credibilidad_alarma AS calificacion_actual_alarma,
    false::boolean AS UsuarioCalificoAlarma,
    'Apagado'::character varying(15) AS CalificacionAlarmaUsuario,
    CASE WHEN t.estado_alarma IS NULL THEN true ELSE false END AS EsAlarmaActiva,
    NULL::bigint AS alarma_id_padre,
    t.credibilidad_alarma AS calificacion_alarma,
    CASE WHEN t.estado_alarma IS NULL THEN true ELSE false END AS estado_alarma,
    false::boolean AS Flag_hubo_captura,
    false::boolean AS flag_alarma_siendo_atendida,
    0::integer AS cantidad_agentes_atendiendo,
    0::integer AS cantidad_interacciones,
    false::boolean AS flag_es_policia,
    ''::character varying(500) AS Descripcionalarma,
    t.flag_red_confianza,
    t.radio_alarmas_mts_actual,
    t.radio_interes_metros,
    t.minutos_vigencia,
    t.idioma AS idioma_destino,
    t.registrationid,
    -- CAMBIO 18-01-2026: Separar logo de emprendimiento y primera foto promocional
    -- Para notificaciones duales: logo (thumbnail colapsado) + primera foto (imagen grande expandida)
    t.url_logo AS url_logo_emprendimiento,           -- Logo del negocio
    pf.primera_foto_url AS url_primera_foto_promo,   -- Primera foto de la promoción
    -- txt_notif: Usar descripcion_personalizada si existe (promocionales), sino generar automático
    CASE
		WHEN t.tipo_subscr_activa_usuario::text = 'Alarmas generadas por mi circulo social'::text THEN
			((((((((('URGENTE! TU PROTEGIDO '::text || t.login_usuario_protegido::text) || ' acaba de lanzar una alarma de tipo: '::text) || t.descripciontipoalarma::text) || ' a '::text) || t.distancia_en_metros) || ' metros de donde estas ubicado. Revisa la alarma para verificar de que se trata. Veracidad: '::text) || t.credibilidad_alarma) || ' por ciento.'::text))::character varying(250)
		WHEN t.tipo_subscr_activa_usuario::text = 'Zona de vigilancia adicional'::text THEN
			((((((('IMPORTANTE! Alguien acaba de lanzar una alarma en una de tus zonas de vigilancia, alerta de tipo: '::text || t.descripciontipoalarma::text) || ' a '::text) || t.distancia_en_metros) || ' metros de la zona que deseas monitorear. Revisa la alarma para verificar de que se trata. Veracidad: '::text) || t.credibilidad_alarma) || ' por ciento.'::text))::character varying(250)
		WHEN t.flag_red_confianza IS TRUE THEN
			((((((('URGENTE RED DE CONFIANZA: Lanzaron alarma cerca de ti, alerta de tipo: '::text || t.descripciontipoalarma::text) || ' a '::text) || t.distancia_en_metros) || ' metros de donde estas ubicado. Revisa la alarma para verificar de que se trata. Veracidad: '::text) || t.credibilidad_alarma) || ' por ciento.'::text))::character varying(250)
		WHEN tipoalarma_id = 13 THEN
			((((('AVISO CERCA DE TI: '::text || t.descripcion_personalizada::text) || ' a '::text) || t.distancia_en_metros) || ' metros de donde estás ubicado. Revisa el anuncio para ayudarnos a que SOSpect se mantenga gratuita.'::text))::character varying(250)
		ELSE
			((((((('Alguien acaba de lanzar una alarma cerca de ti, alerta de tipo: '::text || t.descripciontipoalarma::text) || ' a '::text) || t.distancia_en_metros) || ' metros de donde estas ubicado. Revisa la alarma para verificar de que se trata. Veracidad: '::text) || t.credibilidad_alarma) || ' por ciento.'::text))::character varying(250)
	END AS txt_notif,
   CASE
      WHEN t.estado_alarma IS NULL THEN true
      WHEN t.estado_alarma IS NOT NULL AND t.fecha_alarma > NOW() - interval '90 minutes' THEN true
      ELSE false
   END AS flag_visible_siguiendo
   FROM Prioridades t
   LEFT JOIN PrimeraFotoAlarma pf ON pf.alarma_id = t.alarma_id
   WHERE (t.alarma_id, t.user_id_thirdparty, t.prioridad) IN (
    SELECT p.alarma_id, p.user_id_thirdparty, MIN(p.prioridad)
    FROM Prioridades p
    GROUP BY p.alarma_id, p.user_id_thirdparty);


COMMENT ON VIEW public.vw_notificacion_alarmas IS 'Vista de notificaciones para feed "Siguiendo". Actualizada con soporte para alarmas promocionales (tipoalarma_id=13). ACTUALIZADO 2026-01-29: Usar texto_push_personalizado para notificaciones push en lugar de descripcionalarma.';
