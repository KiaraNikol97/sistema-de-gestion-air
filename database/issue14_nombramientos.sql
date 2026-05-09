-- =====================================================
-- ISSUE #14: Historial de Nombramientos
-- =====================================================

CREATE TABLE IF NOT EXISTS nombramiento (
    id_nombramiento INT PRIMARY KEY AUTO_INCREMENT,
    asambleista_id INT NOT NULL,
    sector_id INT NOT NULL,
    id_puesto INT NOT NULL,
    resolucion_id INT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    estado VARCHAR(20) DEFAULT 'Activo',
    id_usuario_registro INT NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,
    
    INDEX idx_nombramiento_asambleista (asambleista_id),
    INDEX idx_nombramiento_fechas (fecha_inicio, fecha_fin),
    INDEX idx_nombramiento_estado (estado),
    
    CONSTRAINT fk_nombramiento_asambleista 
        FOREIGN KEY (asambleista_id) REFERENCES asambleista(asambleista_id) ON DELETE CASCADE,
    CONSTRAINT fk_nombramiento_sector 
        FOREIGN KEY (sector_id) REFERENCES catalogo_sector(id_sector),
    CONSTRAINT fk_nombramiento_puesto 
        FOREIGN KEY (id_puesto) REFERENCES catalogo_puestos(id_puesto),
    CONSTRAINT fk_nombramiento_usuario 
        FOREIGN KEY (id_usuario_registro) REFERENCES sys_usuario(id_usuario),
    
    CONSTRAINT chk_fechas_nombramiento 
        CHECK (fecha_inicio <= COALESCE(fecha_fin, CURDATE()))
);
