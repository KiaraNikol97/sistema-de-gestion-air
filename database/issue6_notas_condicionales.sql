-- =====================================================
-- ISSUE #6: Motor de Reglas para Notas Condicionales
-- Sprint 3 - Semana 1 (Solo tablas base)
-- Motor: PostgreSQL (Supabase)
-- =====================================================

-- =====================================================
-- 1. CATÁLOGO DE ETAPAS DE PROPUESTA
-- =====================================================

CREATE TABLE IF NOT EXISTS catalogo_etapas_propuestas (
    id_etapa_propuesta SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    orden INT DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE catalogo_etapas_propuestas IS 'Define las etapas del proceso legislativo: Procedencia, Aprobación, etc.';

-- =====================================================
-- 2. CATÁLOGO DE ESTADOS DE PROPUESTA
-- =====================================================

CREATE TABLE IF NOT EXISTS catalogo_estado_propuestas (
    id_estado_propuesta SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    es_terminal BOOLEAN DEFAULT FALSE COMMENT 'Si es un estado final (Aprobada/Rechazada)',
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE catalogo_estado_propuestas IS 'Estados: Pendiente, En Discusión, Aprobada, Rechazada, Derogada';

-- =====================================================
-- 3. TABLA DE LEYENDAS LEGALES (Notas condicionales)
-- =====================================================

CREATE TABLE IF NOT EXISTS leyenda_nota_condicional (
    id_leyenda SERIAL PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL COMMENT 'Código identificador único',
    titulo VARCHAR(200) NOT NULL,
    contenido TEXT NOT NULL,
    aplica_a_etapa_id INT REFERENCES catalogo_etapas_propuestas(id_etapa_propuesta),
    aplica_a_estado_id INT REFERENCES catalogo_estado_propuestas(id_estado_propuesta),
    aplica_a_origen VARCHAR(50) COMMENT 'Consejo_Institucional, 10_Asamblea, Rectoria',
    orden_por_defecto INT DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE leyenda_nota_condicional IS 'Almacena las notas legales que se insertan automáticamente en certificaciones según el origen de la propuesta';

-- =====================================================
-- 4. RELACIÓN PROPUESTA - LEYENDAS APLICABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS propuesta_leyenda (
    id_propuesta_leyenda SERIAL PRIMARY KEY,
    id_propuesta INT NOT NULL,
    id_leyenda INT NOT NULL,
    orden_aparicion INT DEFAULT 0,
    fecha_aplicacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_propuesta, id_leyenda)
);

COMMENT ON TABLE propuesta_leyenda IS 'Relación many-to-many entre propuestas y las leyendas que les aplican';

-- =====================================================
-- 5. DATOS INICIALES (Catálogos y leyendas base)
-- =====================================================

-- Insertar etapas de propuesta
INSERT INTO catalogo_etapas_propuestas (nombre, descripcion, orden) VALUES 
    ('Procedencia', 'Etapa inicial de análisis y dictamen', 1),
    ('Aprobación', 'Etapa de votación en el pleno', 2),
    ('Implementación', 'Etapa de ejecución del acuerdo', 3)
ON CONFLICT (nombre) DO UPDATE SET 
    descripcion = EXCLUDED.descripcion,
    orden = EXCLUDED.orden;

-- Insertar estados de propuesta
INSERT INTO catalogo_estado_propuestas (nombre, descripcion, es_terminal) VALUES 
    ('Pendiente', 'Registrada pero aún no agendada', FALSE),
    ('En Discusión', 'Actual en análisis en comisión o pleno', FALSE),
    ('Aprobada', 'Aprobada por la Asamblea', TRUE),
    ('Rechazada', 'Rechazada por la Asamblea', TRUE),
    ('Derogada', 'Derogada por una propuesta posterior', TRUE)
ON CONFLICT (nombre) DO UPDATE SET 
    descripcion = EXCLUDED.descripcion,
    es_terminal = EXCLUDED.es_terminal;

-- Insertar leyendas condicionales (basadas en el ejemplo de certificación)
INSERT INTO leyenda_nota_condicional (codigo, titulo, contenido, aplica_a_origen, orden_por_defecto) VALUES 
    ('LEG-CI-001', 
     'Nota de Procedencia - Consejo Institucional', 
     'La Secretaría de la AIR no dispone de registros de asistencia detallados para las propuestas en etapa de procedencia originadas por el Consejo Institucional, según lo establecido en el Reglamento Interno.', 
     'Consejo_Institucional', 
     1),
    
    ('LEG-10P-001', 
     'Nota de Procedencia - 10% Asambleístas', 
     'Conforme al artículo 18 del Estatuto Orgánico, las propuestas presentadas por al menos el 10% de los asambleístas no requieren registro de asistencia detallado en la etapa de procedencia. La Secretaría de la AIR certifica únicamente la recepción formal de la moción.', 
     '10_Asamblea', 
     2),
    
    ('LEG-REC-001', 
     'Nota de Recepción General', 
     'El presente documento certifica la participación del asambleísta según los registros históricos de la Secretaría de la AIR. Los datos aquí consignados tienen el carácter de declaración jurada.', 
     NULL, 
     99)
ON CONFLICT (codigo) DO UPDATE SET 
    titulo = EXCLUDED.titulo,
    contenido = EXCLUDED.contenido,
    aplica_a_origen = EXCLUDED.aplica_a_origen;

-- =====================================================
-- 6. TABLA DE ORÍGENES DE PROPUESTA (Complementario)
-- =====================================================

CREATE TABLE IF NOT EXISTS catalogo_origen_propuesta (
    id_origen SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    codigo VARCHAR(20) UNIQUE NOT NULL,
    descripcion TEXT,
    leyenda_por_defecto_id INT REFERENCES leyenda_nota_condicional(id_leyenda),
    activo BOOLEAN DEFAULT TRUE
);

INSERT INTO catalogo_origen_propuesta (nombre, codigo, descripcion) VALUES 
    ('Consejo Institucional', 'CI', 'Propuestas originadas por el Consejo Institucional'),
    ('10% Asambleístas', '10P', 'Propuestas presentadas por al menos el 10% de los asambleístas'),
    ('Rectoría', 'REC', 'Propuestas originadas por la Rectoría'),
    ('Comisión Especial', 'COM', 'Propuestas originadas por una comisión especial')
ON CONFLICT (codigo) DO UPDATE SET 
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion;

-- =====================================================
-- 7. TABLA DE PROPUESTAS (Base - Complementa la existente)
-- =====================================================

-- Nota: agregar columnas faltantes si ya existe la tabla
DO $$ 
BEGIN
    -- Verificar si la columna id_origen existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'propuesta' AND column_name = 'id_origen') THEN
        ALTER TABLE propuesta ADD COLUMN id_origen INT REFERENCES catalogo_origen_propuesta(id_origen);
    END IF;
    
    -- Verificar si la columna id_etapa_propuesta existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'propuesta' AND column_name = 'id_etapa_propuesta') THEN
        ALTER TABLE propuesta ADD COLUMN id_etapa_propuesta INT REFERENCES catalogo_etapas_propuestas(id_etapa_propuesta);
    END IF;
    
    -- Verificar si la columna id_estado_propuesta existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'propuesta' AND column_name = 'id_estado_propuesta') THEN
        ALTER TABLE propuesta ADD COLUMN id_estado_propuesta INT REFERENCES catalogo_estado_propuestas(id_estado_propuesta);
    END IF;
END $$;

-- =====================================================
-- FIN - ISSUE #6
-- =====================================================
