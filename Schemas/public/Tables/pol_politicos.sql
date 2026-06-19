-- Codigo de William Gerardo Escobar Torres
-- Desarrollador: William Gerardo Escobar Torres
-- LinkedIn: https://www.linkedin.com/in/william-gerardo-escobar-torres-29458b66/
-- Correo: wescot2000@gmail.com
-- Registro DNDA: 13-91-449, 19-sept.-2022

-- Table: public.pol_politicos
-- Módulo político: datos maestros del político.
-- Los datos de cargo, territorio y vigencia temporal están en pol_vigencias,
-- lo que permite registrar múltiples mandatos históricos del mismo político.
-- Ejemplo: un alcalde que luego sea gobernador tendrá dos registros en pol_vigencias
-- pero un solo registro aquí.

CREATE TABLE IF NOT EXISTS public.pol_politicos
(
    politico_id     INTEGER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_completo VARCHAR(200)    NOT NULL,
    foto_url        VARCHAR(500),
    -- URL a imagen en S3 bajo prefijo politicos/ (ej: politicos/petro.jpg)
    partido         VARCHAR(150),
    email           VARCHAR(200),
    telefono        VARCHAR(50),
    sitio_web       VARCHAR(500),
    twitter         VARCHAR(150),
    -- Handle con o sin @. Ej: '@petrogustavo' o 'petrogustavo'
    activo          BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
)

TABLESPACE pg_default;

COMMENT ON TABLE public.pol_politicos IS
'Datos maestros del político (nombre, foto, contacto). El cargo, territorio y vigencia están en pol_vigencias para soportar múltiples mandatos históricos del mismo político.';

COMMENT ON COLUMN public.pol_politicos.foto_url IS
'URL de la foto en S3, prefijo politicos/. Ejemplo: https://sospect-s3-data-bucket-prod.s3.amazonaws.com/politicos/petro.jpg';

COMMENT ON COLUMN public.pol_politicos.twitter IS
'Handle de Twitter/X con o sin @. La app agrega https://twitter.com/ al navegar.';

CREATE INDEX IF NOT EXISTS idx_pol_politicos_nombre
    ON public.pol_politicos(nombre_completo);


