-- View: public.vw_listardescripcionesalarma

-- DROP VIEW public.vw_listardescripcionesalarma;

CREATE OR REPLACE VIEW public.vw_listardescripcionesalarma
 AS
 SELECT da.iddescripcion,
    da.alarma_id,
    da.persona_id,
    da.descripcionalarma,
    da.descripcionsospechoso,
    da.descripcionvehiculo,
    da.descripcionarmas,
    da.flageditado,
    da.fechadescripcion,
    COALESCE(cd.calificacion, 'Apagado'::character varying) AS calificacion_otras_descripciones,
    p.user_id_thirdparty AS user_id_thirdparty_calificador,
    pp.user_id_thirdparty AS user_id_thirdparty_propietario,
    COALESCE(da.calificaciondescripcion::integer, 0) AS calificaciondescripcion,
    ta.tipoalarma_id,
    ta.descripciontipoalarma,
    COALESCE(da.idioma_origen, 'en'::character varying) AS idioma_origen,
        CASE
            WHEN al.estado_alarma IS NULL THEN true
            ELSE false
        END AS esalarmaactiva
   FROM descripcionesalarmas da
     JOIN alarmas al ON al.alarma_id = da.alarma_id
     JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
     LEFT JOIN calificadores_descripcion cd ON cd.iddescripcion = da.iddescripcion
     LEFT JOIN personas p ON p.persona_id = cd.persona_id
     LEFT JOIN personas pp ON pp.persona_id = da.persona_id
  WHERE da.veracidadalarma IS NULL
  ORDER BY da.fechadescripcion;

ALTER TABLE public.vw_listardescripcionesalarma
    OWNER TO w4ll4c3;

