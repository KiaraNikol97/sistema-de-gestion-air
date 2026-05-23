-- =====================================================
-- ISSUE #17: Motor de Certificaciones
-- Sprint 3 - Semana 1 (Solo tablas base)
-- Motor: PostgreSQL (Supabase)
-- =====================================================

-- =====================================================
-- 1. TABLA DE CONTROL DE FOLIOS (Consecutivos)
-- =====================================================

CREATE TABLE IF NOT EXISTS control_folio (
    id_control SERIAL PRIMARY KEY,
    anio INT NOT NULL,
    ultimo_numero INT DEFAULT 0,
    prefijo VARCHAR(10) DEFAULT 'DAIR',
    formato VARCHAR(20) DEFAULT 'DAIR-{numero}-{anio}',
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(anio, prefijo)
);

COMMENT ON TABLE control_folio IS 'Control de numeración consecutiva para certificaciones, con bloqueo para evitar duplicados';

-- =====================================================
-- 2. TABLA DE CERTIFICACIONES EMITIDAS
-- =====================================================

CREATE TABLE IF NOT EXISTS certificacion_emitida (
    id_certificacion SERIAL PRIMARY KEY,
    id_asambleista INT NOT NULL REFERENCES asambleista(asambleista_id) ON DELETE RESTRICT,
    folio_unico VARCHAR(50) UNIQUE NOT NULL,
    hash_seguridad VARCHAR(64) NOT NULL COMMENT 'SHA-256 del contenido del documento',
    fecha_emision DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_emision TIME DEFAULT CURRENT_TIME,
    contenido_json JSONB COMMENT 'Snapshot del contenido certificado',
    url_pdf VARCHAR(500),
    estado VARCHAR(20) DEFAULT 'Activa' CHECK (estado IN ('Activa', 'Anulada', 'Suspendida')),
    motivo_anulacion TEXT,
    id_usuario_secretaria INT NOT NULL REFERENCES sys_usuario(id_usuario),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE certificacion_emitida IS 'Registro de todas las certificaciones emitidas por la Secretaría';

-- =====================================================
-- 3. TABLA DE ANULACIÓN DE CERTIFICACIONES
-- =====================================================

CREATE TABLE IF NOT EXISTS anulacion_certificacion (
    id_anulacion SERIAL PRIMARY KEY,
    certificacion_id INT NOT NULL REFERENCES certificacion_emitida(id_certificacion) ON DELETE CASCADE,
    motivo TEXT NOT NULL,
    fecha_anulacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario_anulacion INT NOT NULL REFERENCES sys_usuario(id_usuario),
    justificacion_detalle TEXT,
    certificacion_sustituta_id INT REFERENCES certificacion_emitida(id_certificacion)
);

COMMENT ON TABLE anulacion_certificacion IS 'Bitácora de anulaciones de certificaciones';

-- =====================================================
-- 4. TABLA DE DETALLE DE CERTIFICACIÓN 
-- =====================================================

CREATE TABLE IF NOT EXISTS certificacion_detalle (
    id_detalle SERIAL PRIMARY KEY,
    id_certificacion INT NOT NULL REFERENCES certificacion_emitida(id_certificacion) ON DELETE CASCADE,
    tipo_elemento VARCHAR(50) CHECK (tipo_elemento IN ('Sesion', 'Propuesta', 'Comision', 'Votacion')),
    id_referencia INT NOT NULL COMMENT 'ID de la tabla referenciada',
    descripcion TEXT,
    orden_aparicion INT DEFAULT 0,
    metadata JSONB
);

COMMENT ON TABLE certificacion_detalle IS 'Detalla los elementos específicos que incluye cada certificación';

-- =====================================================
-- 5. TABLA DE VERIFICACIÓN EXTERNA (Código QR)
-- =====================================================

CREATE TABLE IF NOT EXISTS verificacion_externa (
    id_verificacion SERIAL PRIMARY KEY,
    id_certificacion INT NOT NULL REFERENCES certificacion_emitida(id_certificacion) ON DELETE CASCADE,
    codigo_verificacion VARCHAR(50) UNIQUE NOT NULL,
    url_verificacion VARCHAR(500),
    qr_code TEXT COMMENT 'Base64 del código QR',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    veces_verificado INT DEFAULT 0,
    ultima_verificacion TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE verificacion_externa IS 'Almacena códigos QR y URLs para verificación pública de certificaciones';

-- =====================================================
-- 6. TABLA DE SOLICITUDES DE CERTIFICACIÓN (Pendientes)
-- =====================================================

CREATE TABLE IF NOT EXISTS solicitud_certificacion (
    id_solicitud SERIAL PRIMARY KEY,
    id_asambleista INT NOT NULL REFERENCES asambleista(asambleista_id),
    fecha_solicitud DATE NOT NULL DEFAULT CURRENT_DATE,
    periodo_desde DATE,
    periodo_hasta DATE,
    estado VARCHAR(20) DEFAULT 'Pendiente' CHECK (estado IN ('Pendiente', 'En Proceso', 'Completada', 'Rechazada')),
    observaciones TEXT,
    id_usuario_solicitante INT REFERENCES sys_usuario(id_usuario),
    fecha_respuesta DATE,
    id_certificacion_generada INT REFERENCES certificacion_emitida(id_certificacion)
);

-- =====================================================
-- 7. DATOS INICIALES
-- =====================================================

-- Insertar registro inicial de control de folios para el año actual
INSERT INTO control_folio (anio, ultimo_numero, prefijo) 
VALUES (EXTRACT(YEAR FROM CURRENT_DATE), 0, 'DAIR')
ON CONFLICT (anio, prefijo) DO NOTHING;

-- Insertar folios para años ateriores (ejemplo)
INSERT INTO control_folio (anio, ultimo_numero, prefijo) VALUES 
    (2025, 15, 'DAIR'),
    (2024, 42, 'DAIR')
ON CONFLICT (anio, prefijo) DO NOTHING;

-- =====================================================
-- 8. FUNCIÓN PARA GENERAR FOLIO
-- =====================================================

-- Nota: Esta función será usada en un trigger en la Semana 2

CREATE OR REPLACE FUNCTION generar_folio_unico()
RETURNS TRIGGER AS $$
DECLARE
    v_anio INT;
    v_numero INT;
    v_folio VARCHAR(50);
BEGIN
    v_anio := EXTRACT(YEAR FROM NEW.fecha_emision);
    
    -- Bloquear la fila para evitar concurrencia
    SELECT ultimo_numero + 1 INTO v_numero
    FROM control_folio
    WHERE anio = v_anio AND prefijo = 'DAIR'
    FOR UPDATE;
    
    IF NOT FOUND THEN
        INSERT INTO control_folio (anio, ultimo_numero, prefijo)
        VALUES (v_anio, 1, 'DAIR')
        RETURNING ultimo_numero INTO v_numero;
    ELSE
        UPDATE control_folio 
        SET ultimo_numero = v_numero, fecha_actualizacion = CURRENT_TIMESTAMP
        WHERE anio = v_anio AND prefijo = 'DAIR';
    END IF;
    
    -- Formatear folio: DAIR-001-2025
    v_folio := 'DAIR-' || LPAD(v_numero::TEXT, 3, '0') || '-' || v_anio::TEXT;
    
    NEW.folio_unico := v_folio;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generar_folio_unico() IS 'Genera un folio único consecutivo por año con formato DAIR-XXX-YYYY';

-- =====================================================
-- 9. ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_certificacion_folio ON certificacion_emitida(folio_unico);
CREATE INDEX IF NOT EXISTS idx_certificacion_asambleista ON certificacion_emitida(id_asambleista);
CREATE INDEX IF NOT EXISTS idx_certificacion_fecha ON certificacion_emitida(fecha_emision);
CREATE INDEX IF NOT EXISTS idx_certificacion_estado ON certificacion_emitida(estado);
CREATE INDEX IF NOT EXISTS idx_verificacion_codigo ON verificacion_externa(codigo_verificacion);
CREATE INDEX IF NOT EXISTS idx_solicitud_asambleista ON solicitud_certificacion(id_asambleista);
CREATE INDEX IF NOT EXISTS idx_solicitud_estado ON solicitud_certificacion(estado);

-- =====================================================
-- FIN - ISSUE #17
-- =====================================================
