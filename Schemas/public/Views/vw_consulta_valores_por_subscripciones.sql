-- View: public.vw_consulta_valores_por_subscripciones

-- DROP VIEW public.vw_consulta_valores_por_subscripciones;

CREATE OR REPLACE VIEW public.vw_consulta_valores_por_subscripciones
 AS
 SELECT t.tipo_subscr_id,
    t.descripcion_tipo,
    v.cantidad_poderes AS cantidad_poderes_requeridos,
    v.cantidad_subscripcion,
    v.tiempo_subscripcion_horas / 24 AS tiempo_subscripcion_dias,
    ((((('Se requieren '::text || v.cantidad_poderes) || ' poderes para adicionar '::text) || v.cantidad_subscripcion) ||
        CASE
            WHEN t.tipo_subscr_id = 1 THEN ' zona de vigilancia durante '::text
            WHEN t.tipo_subscr_id = 2 THEN ' metros durante '::text
            WHEN t.tipo_subscr_id = 3 THEN ' persona durante '::text
            ELSE NULL::text
        END) ||
        CASE
            WHEN (v.tiempo_subscripcion_horas / 24 / 30) < 1 THEN v.tiempo_subscripcion_horas / 24
            ELSE v.tiempo_subscripcion_horas / 24 / 30
        END) ||
        CASE
            WHEN (v.tiempo_subscripcion_horas / 24 / 30) < 1 THEN ' días'::text
            WHEN (v.tiempo_subscripcion_horas / 24 / 30) = 1 THEN ' mes'::text
            ELSE ' meses'::text
        END AS texto
   FROM valorsubscripciones v
     JOIN tiposubscripcion t ON t.tipo_subscr_id = v.tipo_subscr_id
  ORDER BY t.descripcion_tipo;

ALTER TABLE public.vw_consulta_valores_por_subscripciones
    OWNER TO w4ll4c3;

