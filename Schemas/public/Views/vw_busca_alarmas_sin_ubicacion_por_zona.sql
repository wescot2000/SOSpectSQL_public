-- View: public.vw_busca_alarmas_sin_ubicacion_por_zona

-- DROP VIEW public.vw_busca_alarmas_sin_ubicacion_por_zona;

CREATE OR REPLACE VIEW public.vw_busca_alarmas_sin_ubicacion_por_zona
 AS
 SELECT al.latitud AS latitud_alarma,
    al.longitud AS longitud_alarma,
    ta.tipoalarma_id,
    al.alarma_id,
    al.fecha_alarma,
    ta.descripciontipoalarma,
    ra.radio_double
   FROM radio_alarmas ra,
    alarmas al
     JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
  WHERE ra.radio_alarmas_id = 5 AND al.estado_alarma IS NULL;

ALTER TABLE public.vw_busca_alarmas_sin_ubicacion_por_zona
    OWNER TO w4ll4c3;

