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

-- =====================================================
-- Vistas, Procedimientos y Triggers
-- =====================================================

-- -----------------------------------------------------
-- 1. VISTA: Historial completo de nombramientos activos
-- -----------------------------------------------------
CREATE OR REPLACE VIEW v_historial_nombramientos AS
SELECT 
    n.id_nombramiento,
    a.nombres AS asambleista,
    a.cedula,
    s.nombre AS sector,
    p.nombre AS puesto,
    n.fecha_inicio,
    n.fecha_fin,
    n.estado,
    CASE 
        WHEN n.fecha_fin IS NULL AND n.estado = 'Activo' THEN 'Vigente'
        WHEN n.fecha_fin < CURDATE() THEN 'Vencido'
        ELSE n.estado
    END AS estado_real,
    n.observaciones,
    u.nombre_usuario AS registro_por,
    n.fecha_registro
FROM nombramiento n
INNER JOIN asambleista a ON n.asambleista_id = a.asambleista_id
INNER JOIN catalogo_sector s ON n.sector_id = s.id_sector
INNER JOIN catalogo_puestos p ON n.id_puesto = p.id_puesto
INNER JOIN sys_usuario u ON n.id_usuario_registro = u.id_usuario
ORDER BY n.fecha_inicio DESC;

-- -----------------------------------------------------
-- 2. PROCEDIMIENTO: Registrar nuevo nombramiento
-- -----------------------------------------------------
DELIMITER //

CREATE PROCEDURE sp_registrar_nombramiento(
    IN p_asambleista_id INT,
    IN p_sector_id INT,
    IN p_id_puesto INT,
    IN p_resolucion_id INT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_id_usuario_registro INT,
    IN p_observaciones TEXT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Verificar que el asambleista no tenga un nombramiento activo en el mismo puesto
    IF EXISTS (
        SELECT 1 FROM nombramiento 
        WHERE asambleista_id = p_asambleista_id 
        AND id_puesto = p_id_puesto 
        AND estado = 'Activo'
        AND (fecha_fin IS NULL OR fecha_fin >= CURDATE())
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'El asambleista ya tiene un nombramiento activo para este puesto';
    END IF;
    
    -- Si se provee fecha_fin, validar que sea posterior a fecha_inicio
    IF p_fecha_fin IS NOT NULL AND p_fecha_fin <= p_fecha_inicio THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'La fecha de fin debe ser posterior a la fecha de inicio';
    END IF;
    
    -- Insertar el nuevo nombramiento
    INSERT INTO nombramiento (
        asambleista_id, sector_id, id_puesto, resolucion_id,
        fecha_inicio, fecha_fin, estado, id_usuario_registro, observaciones
    ) VALUES (
        p_asambleista_id, p_sector_id, p_id_puesto, p_resolucion_id,
        p_fecha_inicio, p_fecha_fin, 'Activo', p_id_usuario_registro, p_observaciones
    );
    
    COMMIT;
    
    SELECT LAST_INSERT_ID() AS id_nombramiento;
END //

DELIMITER ;

-- -----------------------------------------------------
-- 3. PROCEDIMIENTO: Finalizar nombramiento (baja)
-- -----------------------------------------------------
DELIMITER //

CREATE PROCEDURE sp_finalizar_nombramiento(
    IN p_id_nombramiento INT,
    IN p_fecha_fin DATE,
    IN p_id_usuario INT,
    IN p_observacion_baja TEXT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    UPDATE nombramiento 
    SET 
        fecha_fin = p_fecha_fin,
        estado = 'Finalizado',
        observaciones = CONCAT(COALESCE(observaciones, ''), ' | BAJA: ', p_observacion_baja)
    WHERE id_nombramiento = p_id_nombramiento
    AND estado = 'Activo';
    
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'No se encontró un nombramiento activo con ese ID';
    END IF;
    
    COMMIT;
END //

DELIMITER ;

-- -----------------------------------------------------
-- 3.5 FUNCIÓN: Validar traslape de nombramientos 
-- -----------------------------------------------------
DELIMITER //

CREATE FUNCTION validar_traslape_nombramiento(
    p_asambleista_id INT,
    p_id_puesto INT,
    p_fecha_inicio DATE,
    p_fecha_fin DATE
) RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE existe_traslape INT;
    
    SELECT COUNT(*) INTO existe_traslape
    FROM nombramiento
    WHERE asambleista_id = p_asambleista_id
    AND id_puesto = p_id_puesto
    AND estado = 'Activo'
    AND (
        (p_fecha_inicio BETWEEN fecha_inicio AND COALESCE(fecha_fin, '9999-12-31'))
        OR (COALESCE(p_fecha_fin, '9999-12-31') BETWEEN fecha_inicio AND COALESCE(fecha_fin, '9999-12-31'))
        OR (fecha_inicio BETWEEN p_fecha_inicio AND COALESCE(p_fecha_fin, '9999-12-31'))
    );
    
    RETURN existe_traslape = 0;
END //

DELIMITER ;
-- -----------------------------------------------------
-- 4. TRIGGER: Evitar fechas superpuestas
-- -----------------------------------------------------
DELIMITER //

CREATE TRIGGER trg_check_nombramiento_overlap
BEFORE INSERT ON nombramiento
FOR EACH ROW
BEGIN
    IF NOT validar_traslape_nombramiento(NEW.asambleista_id, NEW.id_puesto, NEW.fecha_inicio, NEW.fecha_fin) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Ya existe un nombramiento activo para este asambleísta y puesto en el período indicado';
    END IF;
END //

DELIMITER ;

-- -----------------------------------------------------
-- 5. DATOS DE PRUEBA 
-- -----------------------------------------------------
INSERT INTO nombramiento (asambleista_id, sector_id, id_puesto, resolucion_id, fecha_inicio, fecha_fin, estado, id_usuario_registro, observaciones)
VALUES
(1, 1, 1, NULL, '2024-01-15', NULL, 'Activo', 1, 'Nombramiento inicial - período ordinario'),
(2, 2, 2, NULL, '2024-02-01', '2024-12-31', 'Activo', 1, 'Nombramiento con fecha de fin definida'),
(3, 3, 3, NULL, '2024-01-10', '2024-06-30', 'Finalizado', 1, 'Nombramiento ya finalizado');

-- -----------------------------------------------------
-- 6. CONSULTA ÚTIL: Reporte de nombramientos por sector
-- -----------------------------------------------------
CREATE OR REPLACE VIEW v_reporte_nombramientos_sector AS
SELECT 
    s.nombre AS sector,
    p.nombre AS puesto,
    COUNT(n.id_nombramiento) AS total_nombramientos,
    SUM(CASE WHEN n.estado = 'Activo' AND (n.fecha_fin IS NULL OR n.fecha_fin >= CURDATE()) THEN 1 ELSE 0 END) AS activos,
    SUM(CASE WHEN n.estado = 'Finalizado' OR n.fecha_fin < CURDATE() THEN 1 ELSE 0 END) AS historicos
FROM catalogo_sector s
LEFT JOIN nombramiento n ON s.id_sector = n.sector_id
LEFT JOIN catalogo_puestos p ON n.id_puesto = p.id_puesto
GROUP BY s.id_sector, p.id_puesto
ORDER BY s.nombre, total_nombramientos DESC;

-- =====================================================
-- FIN ISSUE #14 (Completo)
-- =====================================================
