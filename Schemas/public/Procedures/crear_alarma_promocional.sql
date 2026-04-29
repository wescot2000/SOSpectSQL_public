-- PROCEDURE: public.crear_alarma_promocional(bigint, bigint, double precision, double precision, text, integer, integer, integer, boolean, character varying, boolean, boolean, integer, character varying, boolean, bigint, bigint, integer, integer, character varying)
-- ACTUALIZADO: 13-01-2026 - Agregado parámetro p_id_emprendimiento para soporte multi-emprendimiento

-- DROP PROCEDURE IF EXISTS public.crear_alarma_promocional(bigint, bigint, double precision, double precision, text, integer, integer, integer, boolean, character varying, boolean, boolean, integer, character varying, boolean, bigint, bigint, integer, integer, character varying);

CREATE OR REPLACE PROCEDURE public.crear_alarma_promocional(
    IN p_persona_id bigint,
    IN p_id_emprendimiento bigint,  -- ✅ AGREGADO 13-01-2026
    IN p_latitud double precision,
    IN p_longitud double precision,
    IN p_descripcion_promocional text,
    IN p_radio_metros integer,
    IN p_duracion_dias integer,
    IN p_cantidad_media integer,
    IN p_logo_habilitado boolean,
    IN p_url_logo character varying,
    IN p_contacto_habilitado boolean,
    IN p_domicilio_habilitado boolean,
    IN p_usuarios_push integer,
    IN p_texto_push character varying,
    IN p_proveedor_acepto_terminos_chat boolean,
    INOUT p_alarma_id bigint,
    INOUT p_subscripcion_id bigint,
    INOUT p_costo_total integer,
    INOUT p_saldo_resultante integer,
    INOUT p_mensaje_error character varying)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    v_saldo_actual INTEGER;
    v_tipoalarma_id INTEGER := 13; -- Promoción local
    v_tipo_subscr_id INTEGER := 4; -- Tipo subscripción publicidad (verificar con SELECT * FROM tiposubscripcion)
    v_fecha_finalizacion TIMESTAMP WITH TIME ZONE;
    v_descripcion_id BIGINT;
    v_emprendimiento_existe BOOLEAN;  -- ✅ ACTUALIZADO 15-01-2026: Para validar existencia
    v_es_propietario BOOLEAN;  -- ✅ AGREGADO 15-01-2026: Para validar cambio de logo
    v_logo_actual VARCHAR(500);  -- ✅ AGREGADO 14-01-2026: Para verificar cambio de logo
BEGIN
    -- Inicializar variables de salida
    p_mensaje_error := NULL;
    p_alarma_id := NULL;
    p_subscripcion_id := NULL;

    -- ✅ ACTUALIZADO 15-01-2026: Validar que el emprendimiento existe
    -- REGLA DE NEGOCIO: Cualquier usuario puede crear promociones para un emprendimiento existente
    -- SOLO el propietario puede cambiar el nombre o logo del emprendimiento
    SELECT EXISTS (
        SELECT 1
        FROM emprendimientos e
        WHERE e.id_emprendimiento = p_id_emprendimiento
          AND e.fecha_fin IS NULL
    ) INTO v_emprendimiento_existe;

    IF NOT v_emprendimiento_existe THEN
        p_mensaje_error := 'El emprendimiento no existe o está inactivo';
        RETURN;
    END IF;

    -- ✅ ACTUALIZADO 15-01-2026: Versionamiento de logo en emprendimientos
    -- SOLO el propietario puede cambiar el logo (validar flag_es_usuario_propietario)
    IF p_url_logo IS NOT NULL THEN
        -- Obtener logo actual y verificar si usuario es propietario
        SELECT
            e.url_logo,
            (e.persona_id_modificadora = p_persona_id AND e.flag_es_usuario_propietario = TRUE)
        INTO v_logo_actual, v_es_propietario
        FROM emprendimientos e
        WHERE e.id_emprendimiento = p_id_emprendimiento
          AND e.fecha_fin IS NULL;

        -- Si el logo cambió, validar permisos y versionar emprendimiento
        IF v_logo_actual IS DISTINCT FROM p_url_logo THEN
            -- Verificar que el usuario sea el propietario antes de cambiar logo
            IF NOT v_es_propietario THEN
                p_mensaje_error := 'Solo el propietario del emprendimiento puede modificar el logo';
                RETURN;
            END IF;
            -- 1. Cerrar registro actual
            UPDATE emprendimientos
            SET fecha_fin = NOW()
            WHERE id_emprendimiento = p_id_emprendimiento
              AND fecha_fin IS NULL;

            -- 2. Crear nuevo registro versionado (copiar métricas del anterior)
            -- CRÍTICO 18-01-2026: Capturar el nuevo ID para que la subscripción apunte a la versión correcta
            INSERT INTO emprendimientos (
                persona_id_modificadora,
                nombre_emprendimiento,
                nit_cedula_propietario,
                nombre_propietario,
                url_logo,  -- Nuevo logo
                flag_es_usuario_propietario,
                fecha_inicio,
                reputacion_promedio,
                total_calificaciones,
                promedio_tiempo_respuesta_minutos,
                promedio_tiempo_entrega_horas,
                porcentaje_satisfaccion,
                total_chats_mes_actual,
                total_transacciones_exitosas,
                badges_ganados,
                fecha_actualizacion_metricas
            )
            SELECT
                persona_id_modificadora,
                nombre_emprendimiento,
                nit_cedula_propietario,
                nombre_propietario,
                p_url_logo,  -- NUEVO LOGO AQUÍ
                flag_es_usuario_propietario,
                NOW(),  -- fecha_inicio = ahora
                reputacion_promedio,
                total_calificaciones,
                promedio_tiempo_respuesta_minutos,
                promedio_tiempo_entrega_horas,
                porcentaje_satisfaccion,
                total_chats_mes_actual,
                total_transacciones_exitosas,
                badges_ganados,
                fecha_actualizacion_metricas
            FROM emprendimientos
            WHERE id_emprendimiento = p_id_emprendimiento
              AND fecha_fin = NOW()  -- El que acabamos de cerrar
            RETURNING id_emprendimiento INTO p_id_emprendimiento;  -- ✅ ACTUALIZAR el parámetro con el nuevo ID
        END IF;
    END IF;

    -- Calcular costo total
    p_costo_total := calcular_costo_publicidad(
        p_radio_metros,
        p_duracion_dias,
        p_cantidad_media,
        p_logo_habilitado,
        p_contacto_habilitado,
        p_domicilio_habilitado,
        p_usuarios_push
    );

    -- Verificar saldo de poderes del usuario
    SELECT saldo_poderes INTO v_saldo_actual
    FROM personas
    WHERE persona_id = p_persona_id;

    IF v_saldo_actual IS NULL THEN
        p_mensaje_error := 'Usuario no encontrado';
        RETURN;
    END IF;

    IF v_saldo_actual < p_costo_total THEN
        p_mensaje_error := 'Poderes insuficientes. Requeridos: ' || p_costo_total || ', Disponibles: ' || v_saldo_actual;
        p_saldo_resultante := v_saldo_actual;
        RETURN;
    END IF;

    -- Calcular fecha de finalización
    v_fecha_finalizacion := NOW() + (p_duracion_dias || ' days')::INTERVAL;

    -- TRANSACCIÓN ATÓMICA
    BEGIN
        -- 1. Descontar poderes
        UPDATE personas
        SET saldo_poderes = saldo_poderes - p_costo_total
        WHERE persona_id = p_persona_id
          AND saldo_poderes >= p_costo_total;

        IF NOT FOUND THEN
            p_mensaje_error := 'Error al descontar poderes (verificación atómica falló)';
            ROLLBACK;
            RETURN;
        END IF;

        -- 2. Crear alarma
        INSERT INTO alarmas (
            tipoalarma_id,
            persona_id,
            latitud,
            longitud,
            fecha_alarma,
            estado_alarma
        )
        VALUES (
            v_tipoalarma_id,
            p_persona_id,
            p_latitud,
            p_longitud,
            NOW(),
            NULL  -- Alarmas promocionales no usan estado_alarma
        )
        RETURNING alarma_id INTO p_alarma_id;

        -- 3. Crear descripción promocional
        INSERT INTO descripcionesalarmas (
            alarma_id,
            persona_id,
            descripcionalarma,
            fechadescripcion,
            latitud_originador,
            longitud_originador
        )
        VALUES (
            p_alarma_id,
            p_persona_id,
            p_descripcion_promocional,
            NOW(),
            p_latitud,
            p_longitud
        )
        RETURNING iddescripcion INTO v_descripcion_id;

        -- 4. Crear subscripción publicitaria
        -- ✅ ACTUALIZADO 13-01-2026: Agregado id_emprendimiento
        -- ✅ ACTUALIZADO 14-01-2026: Eliminados tipo_subscripcion y url_logo (movidos a emprendimientos)
        INSERT INTO subscripciones (
            persona_id,
            tipo_subscr_id,
            alarma_id,
            id_emprendimiento,  -- ✅ AGREGADO 13-01-2026
            fecha_activacion,
            fecha_finalizacion,
            radio_metros,
            duracion_dias,
            poderes_consumidos,
            logo_habilitado,
            contacto_habilitado,
            domicilio_habilitado,
            cantidad_media_adjunta,
            usuarios_push_notificados,
            texto_push_personalizado,
            proveedor_acepto_terminos_chat,
            fecha_proveedor_acepto_terminos
        )
        VALUES (
            p_persona_id,
            v_tipo_subscr_id,
            p_alarma_id,
            p_id_emprendimiento,  -- ✅ AGREGADO 13-01-2026
            NOW(),
            v_fecha_finalizacion,
            p_radio_metros,
            p_duracion_dias,
            p_costo_total,
            p_logo_habilitado,
            p_contacto_habilitado,
            p_domicilio_habilitado,
            p_cantidad_media,
            p_usuarios_push,
            p_texto_push,
            p_proveedor_acepto_terminos_chat,
            CASE WHEN p_proveedor_acepto_terminos_chat THEN NOW() ELSE NULL END
        )
        RETURNING subscripcion_id INTO p_subscripcion_id;

        -- 5. Registrar transacción de poderes
        -- Nota: La tabla transacciones_personas no tiene las columnas cantidad_poderes/descripcion
        -- El descuento ya se realizó en el UPDATE de personas (paso 1)
        INSERT INTO transacciones_personas (
            persona_id,
            tipo_transaccion,
            fecha_transaccion,
            ip_transaccion
        )
        VALUES (
            p_persona_id,
            'consumo_publicidad',
            NOW(),
            ''  -- IP no disponible en stored procedure
        );

        -- Calcular saldo resultante
        SELECT saldo_poderes INTO p_saldo_resultante
        FROM personas
        WHERE persona_id = p_persona_id;

        -- TODO: Si p_usuarios_push > 0, enviar notificaciones push
        -- (Esto se implementará en la API, no en SQL)

    EXCEPTION
        WHEN OTHERS THEN
            p_mensaje_error := 'Error al crear alarma promocional: ' || SQLERRM;
            ROLLBACK;
            RETURN;
    END;
END;
$BODY$;


COMMENT ON PROCEDURE public.crear_alarma_promocional(bigint, bigint, double precision, double precision, text, integer, integer, integer, boolean, character varying, boolean, boolean, integer, character varying, boolean, bigint, bigint, integer, integer, character varying)
    IS 'Crea una alarma promocional completa: descuenta poderes, crea alarma, descripción y subscripción vinculada a un emprendimiento. Valida permisos del usuario sobre el emprendimiento. Incluye aceptación de términos del proveedor para chat. Es una transacción atómica que revierte todos los cambios si falla algún paso. ACTUALIZADO 13-01-2026: Agregado parámetro p_id_emprendimiento para soporte multi-emprendimiento.';
