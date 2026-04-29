-- Table: public.categoria_alarma

-- DROP TABLE IF EXISTS public.categoria_alarma;

CREATE TABLE IF NOT EXISTS public.categoria_alarma
(
    categoria_alarma_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(500)
)

TABLESPACE pg_default;


COMMENT ON TABLE public.categoria_alarma IS
'Tabla de categorías de alarmas para clasificación consistente y escalable. Las categorías permiten agrupar tipos de alarma y facilitar análisis territorial y político.';

COMMENT ON COLUMN public.categoria_alarma.nombre IS
'Nombre único de la categoría (ej: SEGURIDAD, POLITICA, INFRAESTRUCTURA)';

COMMENT ON COLUMN public.categoria_alarma.descripcion IS
'Descripción detallada del propósito de la categoría';

-- Índice para búsquedas rápidas por nombre
CREATE INDEX IF NOT EXISTS idx_categoria_alarma_nombre
ON public.categoria_alarma(nombre);

-- Insertar categorías iniciales
INSERT INTO public.categoria_alarma (nombre, descripcion) VALUES
('SEGURIDAD', 'Alarmas relacionadas con incidentes de seguridad ciudadana (robos, asaltos, zonas peligrosas, etc.)'),
('POLITICA', 'Alarmas relacionadas con eventos políticos, protestas, manifestaciones, cierre de vías por eventos políticos. No se refiere a afiliación partidista, sino a análisis de gestión pública, gobernabilidad, orden público o cumplimiento institucional.'),
('INFRAESTRUCTURA', 'Reportes sobre el estado de infraestructura pública (vías dañadas, servicios públicos, problemas de movilidad, etc.)'),
('INFORMATIVA', 'Información general de interés comunitario que no cae en otras categorías.'),
('ENTRETENIMIENTO', 'Eventos culturales, deportivos, sociales de interés comunitario.'),
('PUBLICIDAD', 'Alarmas de tipo publicitario (promociones locales, eventos comerciales, etc.)');
