-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- FUNCTION: public.obtener_traduccion(text, text)

-- DROP FUNCTION IF EXISTS public.obtener_traduccion(text, text);

CREATE OR REPLACE FUNCTION public.obtener_traduccion(
	p_clave text,
	p_idioma text)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$

DECLARE 
    traduccion TEXT;
BEGIN
    -- Intentar obtener la traducción
    SELECT texto INTO traduccion FROM traducciones WHERE clave = p_clave AND idioma = p_idioma;

    -- Si la traducción no se encuentra
    IF traduccion IS NULL THEN
        -- Insertar en la tabla de seguimiento para traducciones faltantes
        INSERT INTO idiomaspendientesagregar(idioma, clave, cantidad_ocurrencias)
        VALUES(p_idioma, p_clave, 1)
        ON CONFLICT (idioma, clave)
        DO UPDATE SET cantidad_ocurrencias = idiomaspendientesagregar.cantidad_ocurrencias + 1;

        -- Asignar un valor predeterminado a traducción (puede ser un mensaje en inglés o cualquier otro mensaje predeterminado)
        traduccion := 'Translation not found'; 
    END IF;

    RETURN traduccion;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error obtaining translation';
END;
$BODY$;



