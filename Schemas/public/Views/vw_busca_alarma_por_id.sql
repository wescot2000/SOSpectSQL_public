-- View: public.vw_busca_alarma_por_id

-- DROP VIEW public.vw_busca_alarma_por_id;

CREATE OR REPLACE VIEW public.vw_busca_alarma_por_id
 AS
 SELECT p.user_id_thirdparty,
    p.persona_id,
    alper.user_id_thirdparty AS user_id_creador_alarma,
    p.login AS login_usuario_notificar,
    al.latitud AS latitud_alarma,
    al.longitud AS longitud_alarma,
    al.latitud AS latitud_entrada,
    al.longitud AS longitud_entrada,
    NULL::text AS tipo_subscr_activa_usuario,
    NULL::text AS fecha_activacion_subscr,
    NULL::text AS fecha_finalizacion_subscr,
    0::numeric AS distancia_en_metros,
    'MYSELF'::text AS relacion_social,
    al.alarma_id,
    al.fecha_alarma,
    ta.descripciontipoalarma,
    ta.tipoalarma_id,
    60::smallint AS tiemporefrescoubicacion,
        CASE
            WHEN p.user_id_thirdparty::text = alper.user_id_thirdparty::text THEN true
            ELSE false
        END AS flag_propietario_alarma,
    COALESCE((((verdaderos.cantidad_verdadero * 100)::numeric(18,2) / total.cantidad_total::numeric(18,2))::numeric(18,2) * (alper.credibilidad_persona / 100::numeric)::numeric(18,2))::numeric(5,2), 100.00) AS calificacion_actual_alarma,
        CASE
            WHEN dal.veracidadalarma IS NOT NULL THEN 1::boolean
            ELSE 0::boolean
        END AS usuariocalificoalarma,
        CASE
            WHEN dal.veracidadalarma = true THEN 'Verdadero'::character varying(15)
            WHEN dal.veracidadalarma = false THEN 'Negativo'::character varying(15)
            ELSE 'Apagado'::character varying(15)
        END AS calificacionalarmausuario,
        CASE
            WHEN al.estado_alarma IS NULL THEN true
            ELSE false
        END AS esalarmaactiva,
    al.calificacion_alarma,
    case when al.estado_alarma is null  then cast(true as boolean) else cast(false as boolean) end as estado_alarma,
    coalesce(dal.Flag_hubo_captura,cast(false as boolean)) as Flag_hubo_captura,
    case when  (select count(*) as cantidad_agentes_atendiendo from atencion_policiaca ap where ap.alarma_id=al.alarma_id) > 0 then cast (true as boolean) else cast (false as boolean) end as flag_alarma_siendo_atendida,
    (select count(*) as cantidad_agentes_atendiendo from atencion_policiaca ap where ap.alarma_id=al.alarma_id) as cantidad_agentes_atendiendo,
    (select count(*) as cantidad_interacciones from descripcionesalarmas dalt where dalt.alarma_id = al.alarma_id and dal.veracidadalarma is null) as cantidad_interacciones,
    p.flag_es_policia
   FROM alarmas al
     JOIN personas p ON p.persona_id = al.persona_id
     JOIN personas alper ON alper.persona_id = al.persona_id
     LEFT JOIN dispositivos dis ON dis.persona_id = p.persona_id AND dis.fecha_fin IS NULL
     JOIN tipoalarma ta ON ta.tipoalarma_id = al.tipoalarma_id
     LEFT JOIN descripcionesalarmas dal ON dal.alarma_id = al.alarma_id AND dal.persona_id = p.persona_id AND dal.veracidadalarma IS NOT NULL
     LEFT JOIN ( SELECT al_1.alarma_id,
                CASE
                    WHEN count(*) = 0 THEN 1::bigint
                    ELSE count(*)
                END AS cantidad_verdadero
           FROM alarmas al_1
             LEFT JOIN descripcionesalarmas da ON al_1.alarma_id = da.alarma_id AND da.veracidadalarma = true
          GROUP BY al_1.alarma_id) verdaderos ON al.alarma_id = verdaderos.alarma_id
     LEFT JOIN ( SELECT al_1.alarma_id,
                CASE
                    WHEN count(*) = 0 THEN 1::bigint
                    ELSE count(*)
                END AS cantidad_total
           FROM alarmas al_1
             LEFT JOIN descripcionesalarmas da ON al_1.alarma_id = da.alarma_id
          GROUP BY al_1.alarma_id) total ON al.alarma_id = total.alarma_id;

ALTER TABLE public.vw_busca_alarma_por_id
    OWNER TO w4ll4c3;

