-- ===========================================================
-- ISSUE #10 - Jerarquía de Reglamentos (Estructura Recursiva)
-- Sprint 2 - Semana 2
-- ===========================================================

-- =====================================================
-- 1. CATÁLOGOS BASE
-- =====================================================

-- Catálogo de niveles de reglamento
CREATE TABLE IF NOT EXISTS catalogo_nivel_reglamento (
    id_nivel_reglamento INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    orden INT NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);

-- Catálogo de estado de vigencia
CREATE TABLE IF NOT EXISTS catalogo_estado_vigencia (
    id_estado_vigencia INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT
);

-- =====================================================
-- 2. TABLA DE REGLAMENTOS (RAÍZ)
-- =====================================================

CREATE TABLE IF NOT EXISTS reglamento (
    id_reglamento INT PRIMARY KEY AUTO_INCREMENT,
    nombre_normativa VARCHAR(200) NOT NULL,
    sigla VARCHAR(20) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 3. DATOS INICIALES 
-- =====================================================

-- Estado de vigencia
INSERT INTO catalogo_estado_vigencia (nombre, descripcion) VALUES 
    ('Vigente', 'Activo actualmente'),
    ('Histórico', 'Versión anterior ya no vigente'),
    ('Derogado', 'Eliminado por reforma posterior')
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);

-- Niveles de reglamento
INSERT INTO catalogo_nivel_reglamento (nombre, orden) VALUES 
    ('Título', 1),
    ('Capítulo', 2),
    ('Artículo', 3),
    ('Inciso', 4),
    ('Sub-inciso', 5)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);

-- Reglamentos base
INSERT INTO reglamento (nombre_normativa, sigla) VALUES 
    ('Estatuto Orgánico del TEC', 'EO'),
    ('Reglamento de Enseñanza-Aprendizaje', 'REA'),
    ('Reglamento de Carrera Profesional', 'RCP')
ON DUPLICATE KEY UPDATE nombre_normativa = VALUES(nombre_normativa);


