-- View: public.vw_consulta_valores_por_subscripciones
-- Modificado: 2026-04-02
-- Cambios: Se eliminaron tipos 4, 5, 6 de valorsubscripciones (anuncios con costos estáticos erróneos).
--          Se agregó UNION ALL con configuracion_costos_promocionales para mostrar los costos
--          reales por componente del anuncio publicitario.

-- DROP VIEW public.vw_consulta_valores_por_subscripciones;

CREATE OR REPLACE VIEW public.vw_consulta_valores_por_subscripciones
 AS
 -- Suscripciones de vigilancia, radio y círculo social (tipos 1, 2, 3)
 SELECT t.tipo_subscr_id,
    t.descripcion_tipo,
    v.cantidad_poderes AS cantidad_poderes_requeridos,
    v.cantidad_subscripcion,
    COALESCE(v.tiempo_subscripcion_horas / 24, 0) AS tiempo_subscripcion_dias,
    ((((('Se requieren '::text || v.cantidad_poderes) || ' poderes para agregar '::text) || v.cantidad_subscripcion) ||
        CASE
            WHEN t.tipo_subscr_id = 1 THEN ' zona de vigilancia durante '::text
            WHEN t.tipo_subscr_id = 2 THEN ' metros durante '::text
            WHEN t.tipo_subscr_id = 3 THEN ' persona durante '::text
            ELSE ''::text
        END) ||
        CASE
            WHEN (v.tiempo_subscripcion_horas / 24 / 30) < 1 THEN (v.tiempo_subscripcion_horas / 24)::text
            ELSE (v.tiempo_subscripcion_horas / 24 / 30)::text
        END) ||
        CASE
            WHEN (v.tiempo_subscripcion_horas / 24 / 30) < 1 THEN ' días'::text
            WHEN (v.tiempo_subscripcion_horas / 24 / 30) = 1 THEN ' mes'::text
            ELSE ' meses'::text
        END AS texto
   FROM valorsubscripciones v
     JOIN tiposubscripcion t ON t.tipo_subscr_id = v.tipo_subscr_id

 UNION ALL

 -- Costos de anuncios publicitarios por componente (desde configuracion_costos_promocionales)
 SELECT 100 AS tipo_subscr_id,
    'Anuncio - costo base' AS descripcion_tipo,
    costo_base_promocion AS cantidad_poderes_requeridos,
    1 AS cantidad_subscripcion,
    0 AS tiempo_subscripcion_dias,
    'Se requieren ' || costo_base_promocion || ' poderes para publicar 1 anuncio publicitario (costo base)' AS texto
   FROM public.configuracion_costos_promocionales

 UNION ALL

 SELECT 101,
    'Anuncio - logo',
    costo_logo,
    1, 0,
    'Se requieren ' || costo_logo || ' poderes adicionales por incluir logo en el anuncio'
   FROM public.configuracion_costos_promocionales

 UNION ALL

 SELECT 102,
    'Anuncio - contacto',
    costo_contacto,
    1, 0,
    'Se requieren ' || costo_contacto || ' poder adicional por habilitar chat de contacto en el anuncio'
   FROM public.configuracion_costos_promocionales

 UNION ALL

 SELECT 103,
    'Anuncio - domicilio',
    costo_domicilio,
    1, 0,
    'Se requieren ' || costo_domicilio || ' poder adicional por habilitar opción de domicilio en el anuncio'
   FROM public.configuracion_costos_promocionales

 UNION ALL

 SELECT 104,
    'Anuncio - alcance geográfico',
    costo_por_500m_extra,
    500, 0,
    'Se requieren ' || costo_por_500m_extra || ' poderes adicionales por cada 500 metros de alcance del anuncio'
   FROM public.configuracion_costos_promocionales

 UNION ALL

 SELECT 105,
    'Anuncio - duración',
    costo_por_dia_extra,
    1, 1,
    'Se requieren ' || costo_por_dia_extra || ' poderes adicionales por cada día de duración del anuncio'
   FROM public.configuracion_costos_promocionales

 UNION ALL

 SELECT 106,
    'Anuncio - multimedia',
    costo_por_media_extra,
    1, 0,
    'Se requieren ' || costo_por_media_extra || ' poderes adicionales por cada archivo multimedia en el anuncio'
   FROM public.configuracion_costos_promocionales

 UNION ALL

 SELECT 107,
    'Anuncio - notificaciones push',
    costo_por_50_usuarios_push,
    50, 0,
    'Se requieren ' || costo_por_50_usuarios_push || ' poderes adicionales por notificar a 50 usuarios del anuncio'
   FROM public.configuracion_costos_promocionales

 ORDER BY tipo_subscr_id;


