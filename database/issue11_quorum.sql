-- =====================================================
-- ISSUE #11: Control de Quórum
-- Sprint 3 - Semana 1 (Solo tablas base)
-- Motor: PostgreSQL (Supabase)
-- =====================================================

-- =====================================================
-- 1. CATÁLOGO DE TIPOS DE SESIÓN
-- =====================================================

CREATE TABLE IF NOT EXISTS catalogo_tipo_sesion (
    id_tipo_sesion SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    quorum_porcentaje DECIMAL(5,2) DEFAULT 50.00 COMMENT 'Porcentaje mínimo de asistencia requerido',
    requiere_mayoria_calificada BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE catalogo_tipo_sesion IS 'Define los tipos de sesión: Ordinaria, Extraordinaria, Solemne, etc.';

-- =====================================================
-- 2. CATÁLOGO DE TIPOS DE MODALIDAD
-- =====================================================

CREATE TABLE IF NOT EXISTS catalogo_tipo_modalidad (
    id_tipo_modalidad SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE catalogo_tipo_modalidad IS 'Define la modalidad: Presencial, Virtual, Mixta';

-- =====================================================
-- 3. CATÁLOGO DE ESTADOS DE ASISTENCIA
-- =====================================================

CREATE TABLE IF NOT EXISTS catalogo_asistencia (
    id_estado_asistencia SERIAL PRIMARY KEY,
    nombre VARCHAR(30) UNIQUE NOT NULL,
    descripcion TEXT,
    computa_para_quorum BOOLEAN DEFAULT TRUE,
    activo BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE catalogo_asistencia IS 'Estados: Presente, Ausente, Justificado, Retardo';

-- =====================================================
-- 4. TABLA DE SESIONES
-- =====================================================

CREATE TABLE IF NOT EXISTS sesion (
    id_sesion SERIAL PRIMARY KEY,
    id_tipo_modalidad INT REFERENCES catalogo_tipo_modalidad(id_tipo_modalidad),
    id_tipo_sesion INT REFERENCES catalogo_tipo_sesion(id_tipo_sesion),
    numero_sesion VARCHAR(50) UNIQUE NOT NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME,
    hora_fin TIME,
    link_acta VARCHAR(500),
    quorum_requerido INT COMMENT 'Número mínimo de asambleístas requeridos',
    total_asambleistas INT COMMENT 'Total de asambleístas en la fecha de la sesión',
    estado VARCHAR(30) DEFAULT 'Programada' CHECK (estado IN ('Programada', 'En Curso', 'Finalizada', 'Cancelada')),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario_registro INT REFERENCES sys_usuario(id_usuario)
);

COMMENT ON TABLE sesion IS 'Registro de las sesiones de la AIR';

-- =====================================================
-- 5. TABLA DE ACTAS
-- =====================================================

CREATE TABLE IF NOT EXISTS acta (
    id_acta SERIAL PRIMARY KEY,
    id_sesion INT NOT NULL REFERENCES sesion(id_sesion) ON DELETE CASCADE,
    numero_acta VARCHAR(50) UNIQUE NOT NULL,
    fecha_aprobacion DATE,
    url_documento VARCHAR(500),
    contenido_resumen TEXT,
    observaciones TEXT,
    estado VARCHAR(30) DEFAULT 'Borrador' CHECK (estado IN ('Borrador', 'En Revision', 'Aprobada', 'Publicada')),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario_registro INT REFERENCES sys_usuario(id_usuario)
);

-- =====================================================
-- 6. TABLA DE ASISTENCIA A SESIONES PLENARIAS
-- =====================================================

CREATE TABLE IF NOT EXISTS asistencia_sesion_plenaria (
    id_asistencia SERIAL PRIMARY KEY,
    id_asambleista INT NOT NULL REFERENCES asambleista(asambleista_id) ON DELETE CASCADE,
    id_sesion INT NOT NULL REFERENCES sesion(id_sesion) ON DELETE CASCADE,
    id_estado_asistencia INT NOT NULL REFERENCES catalogo_asistencia(id_estado_asistencia),
    hora_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,
    UNIQUE(id_asambleista, id_sesion)
);

COMMENT ON TABLE asistencia_sesion_plenaria IS 'Registro de asistencia de asambleístas a sesiones plenarias';

-- =====================================================
-- 7. TABLA DE VOTACIONES 
-- =====================================================

CREATE TABLE IF NOT EXISTS votacion (
    id_votacion SERIAL PRIMARY KEY,
    id_sesion INT NOT NULL REFERENCES sesion(id_sesion) ON DELETE CASCADE,
    id_propuesta INT,
    id_elemento_normativo INT,
    numero_votacion VARCHAR(50),
    tipo_votacion VARCHAR(30) DEFAULT 'Publica' CHECK (tipo_votacion IN ('Publica', 'Secreta')),
    votos_favor INT DEFAULT 0,
    votos_contra INT DEFAULT 0,
    votos_abstencion INT DEFAULT 0,
    total_votantes INT DEFAULT 0,
    resultado VARCHAR(30) CHECK (resultado IN ('Aprobada', 'Rechazada', 'Empate', 'Pendiente')),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 8. DATOS INICIALES
-- =====================================================

-- Insertar tipos de sesión
INSERT INTO catalogo_tipo_sesion (nombre, descripcion, quorum_porcentaje, requiere_mayoria_calificada) VALUES 
    ('Ordinaria', 'Sesión regular programada en el calendario', 50.00, FALSE),
    ('Extraordinaria', 'Sesión convocada con urgencia fuera del calendario', 66.00, TRUE),
    ('Solemne', 'Sesión protocolaria o conmemorativa', 33.00, FALSE)
ON CONFLICT (nombre) DO UPDATE SET 
    descripcion = EXCLUDED.descripcion,
    quorum_porcentaje = EXCLUDED.quorum_porcentaje;

-- Insertar tipos de modalidad
INSERT INTO catalogo_tipo_modalidad (nombre, descripcion) VALUES 
    ('Presencial', 'Sesión realizada en el recinto de la AIR'),
    ('Virtual', 'Sesión realizada por videoconferencia'),
    ('Mixta', 'Combinación de presencial y virtual')
ON CONFLICT (nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion;

-- Insertar estados de asistencia
INSERT INTO catalogo_asistencia (nombre, descripcion, computa_para_quorum) VALUES 
    ('Presente', 'Asistió a la sesión', TRUE),
    ('Ausente', 'No asistió a la sesión', FALSE),
    ('Justificado', 'Ausencia justificada según reglamento', FALSE),
    ('Retardo', 'Llegó tarde pero participó', TRUE)
ON CONFLICT (nombre) DO UPDATE SET 
    descripcion = EXCLUDED.descripcion,
    computa_para_quorum = EXCLUDED.computa_para_quorum;

-- =====================================================
-- 9. ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_sesion_fecha ON sesion(fecha);
CREATE INDEX IF NOT EXISTS idx_sesion_estado ON sesion(estado);
CREATE INDEX IF NOT EXISTS idx_asistencia_sesion ON asistencia_sesion_plenaria(id_sesion);
CREATE INDEX IF NOT EXISTS idx_asistencia_asambleista ON asistencia_sesion_plenaria(id_asambleista);
CREATE INDEX IF NOT EXISTS idx_acta_sesion ON acta(id_sesion);
CREATE INDEX IF NOT EXISTS idx_votacion_sesion ON votacion(id_sesion);

-- =====================================================
-- FIN - ISSUE #11
-- =====================================================
