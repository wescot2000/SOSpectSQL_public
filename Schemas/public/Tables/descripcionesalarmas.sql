-- Table: public.descripcionesalarmas

-- DROP TABLE IF EXISTS public.descripcionesalarmas;

CREATE TABLE IF NOT EXISTS public.descripcionesalarmas
(
    iddescripcion bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    alarma_id bigint NOT NULL,
    persona_id bigint NOT NULL,
    descripcionalarma character varying(500) COLLATE pg_catalog."default",
    descripcionsospechoso character varying(500) COLLATE pg_catalog."default",
    descripcionvehiculo character varying(500) COLLATE pg_catalog."default",
    descripcionarmas character varying(500) COLLATE pg_catalog."default",
    fechadescripcion timestamp with time zone NOT NULL,
    calificaciondescripcion smallint,
    veracidadalarma boolean,
    flageditado boolean DEFAULT false,
    latitud_originador numeric(9,6),
    longitud_originador numeric(9,6),
    ip_usuario_originador character varying(50) COLLATE pg_catalog."default",
    distancia_alarma_originador numeric(9,2),
    idioma_origen character varying(10) COLLATE pg_catalog."default",
    flag_es_cierre_alarma boolean,
    flag_hubo_captura boolean,
    flag_persona_encontrada boolean,
    flag_mascota_recuperada boolean,
    CONSTRAINT pk_descripcionesalarmas PRIMARY KEY (iddescripcion),
    CONSTRAINT fk_descripc_reference_alarmas FOREIGN KEY (alarma_id)
        REFERENCES public.alarmas (alarma_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT fk_descripc_reference_personas FOREIGN KEY (persona_id)
        REFERENCES public.personas (persona_id) MATCH SIMPLE
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)

TABLESPACE pg_default;


-- Comentarios (Actualizado 14-01-2026)
COMMENT ON TABLE public.descripcionesalarmas IS
'Descripciones de alarmas. Para alarmas promocionales, EXACTAMENTE UNA descripción por alarma. Los campos forenses son obligatorios para auditoría legal.';

COMMENT ON COLUMN public.descripcionesalarmas.idioma_origen IS
'Idioma del dispositivo del usuario que creó la descripción. Capturado desde CultureInfo.CurrentCulture.TwoLetterISOLanguageName. Usado para traducción automática: API detecta cuando idioma_origen ≠ idioma_destino. Agregado: 12-01-2026 (Manual 0712-21).';

COMMENT ON COLUMN public.descripcionesalarmas.ip_usuario_originador IS
'Dirección IP del usuario que creó la descripción. Capturado desde HttpContext.Connection.RemoteIpAddress. PROPÓSITO FORENSE: Investigaciones gubernamentales, detección de spam. Agregado: 12-01-2026 (Manual 0712-21).';

COMMENT ON COLUMN public.descripcionesalarmas.latitud_originador IS
'Latitud GPS del usuario al momento de crear la descripción. Usado junto con alarmas.latitud para calcular distancia_alarma_originador. ANTI-FRAUDE: Detectar sabotaje empresarial o spam desde ubicaciones remotas. Agregado: 12-01-2026 (Manual 0712-21).';

COMMENT ON COLUMN public.descripcionesalarmas.longitud_originador IS
'Longitud GPS del usuario al momento de crear la descripción. Usado junto con alarmas.longitud para calcular distancia_alarma_originador. ANTI-FRAUDE: Detectar sabotaje empresarial o spam desde ubicaciones remotas. Agregado: 12-01-2026 (Manual 0712-21).';

COMMENT ON COLUMN public.descripcionesalarmas.distancia_alarma_originador IS
'Distancia en kilómetros entre la ubicación del usuario (latitud_originador, longitud_originador) y la ubicación de la alarma (alarmas.latitud, alarmas.longitud). Calculado con fórmula Haversine. ANTI-FRAUDE: Caso fraudulento = usuario en Bogotá creando publicidad negativa para restaurante en Medellín (distancia > 200km). Caso legítimo = usuario a 2km de su negocio. REGLA DE NEGOCIO: Si distancia > 5km, marcar para revisión manual. Si distancia > 50km, auto-bloquear (posible spam internacional). Agregado: 12-01-2026 (Manual 0712-21).';

COMMENT ON COLUMN public.descripcionesalarmas.flag_persona_encontrada IS
'Indica si la persona perdida fue encontrada al momento del cierre de alarma. Solo aplica para tipo_cierre=cierre_persona (tipoalarma_id=5). Agregado: 06-02-2026.';

COMMENT ON COLUMN public.descripcionesalarmas.flag_mascota_recuperada IS
'Indica si la mascota perdida fue recuperada al momento del cierre de alarma. Solo aplica para tipo_cierre=cierre_mascota (tipoalarma_id=4). Agregado: 06-02-2026.';