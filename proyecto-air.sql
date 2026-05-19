-- =====================================================
-- SISTEMA DE GESTIÓN AIR
-- Sprint 2 - Semana 2
-- =====================================================

-- =====================================================
-- 1. CATÁLOGOS COMPARTIDOS
-- =====================================================

CREATE TABLE IF NOT EXISTS catalogo_sector (
    id_sector INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS catalogo_puestos (
    id_puesto INT PRIMARY KEY AUTO_INCREMENT,
    nombre_puesto VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS catalogo_nivel_reglamento (
    id_nivel_reglamento INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    orden INT NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS catalogo_estado_vigencia (
    id_estado_vigencia INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT
);

CREATE TABLE IF NOT EXISTS catalogo_tipo_reforma (
    id_tipo_reforma INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT
);


-- =====================================================
-- 2. ASAMBLEÍSTAS - Issue #9
-- =====================================================

DROP TABLE IF EXISTS bitacora_asambleistas;
DROP TABLE IF EXISTS asambleista;

CREATE TABLE IF NOT EXISTS asambleista (
    id_asambleista INT AUTO_INCREMENT PRIMARY KEY,
    cedula VARCHAR(11) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    correo_institucional VARCHAR(150),

    CONSTRAINT chk_cedula_formato 
    CHECK (cedula REGEXP '^[0-9]-[0-9]{4}-[0-9]{4}$'),

    CONSTRAINT chk_nombre_no_vacio 
    CHECK (TRIM(nombre) <> ''),

    CONSTRAINT chk_correo_institucional
    CHECK (
        correo_institucional IS NULL 
        OR correo_institucional = ''
        OR correo_institucional LIKE '%@%'
    )
);

CREATE TABLE IF NOT EXISTS bitacora_asambleistas (
    id_bitacora_asambleista INT AUTO_INCREMENT PRIMARY KEY,
    id_asambleista INT NOT NULL,

    cedula_anterior VARCHAR(11),
    cedula_nueva VARCHAR(11),

    nombre_anterior VARCHAR(150),
    nombre_nuevo VARCHAR(150),

    correo_anterior VARCHAR(150),
    correo_nuevo VARCHAR(150),

    razon_cambio VARCHAR(255),
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_asambleista) 
        REFERENCES asambleista(id_asambleista)
        ON DELETE CASCADE
);

DROP TRIGGER IF EXISTS trg_bitacora_update_asambleista;

DELIMITER $$

CREATE TRIGGER trg_bitacora_update_asambleista
AFTER UPDATE ON asambleista
FOR EACH ROW
BEGIN
    IF OLD.cedula <> NEW.cedula
       OR OLD.nombre <> NEW.nombre
       OR IFNULL(OLD.correo_institucional, '') <> IFNULL(NEW.correo_institucional, '') THEN

        INSERT INTO bitacora_asambleistas (
            id_asambleista,
            cedula_anterior,
            cedula_nueva,
            nombre_anterior,
            nombre_nuevo,
            correo_anterior,
            correo_nuevo,
            razon_cambio
        )
        VALUES (
            OLD.id_asambleista,
            OLD.cedula,
            NEW.cedula,
            OLD.nombre,
            NEW.nombre,
            OLD.correo_institucional,
            NEW.correo_institucional,
            'Actualización de datos personales del asambleísta'
        );
    END IF;
END$$

DELIMITER ;


-- =====================================================
-- 3. SEGURIDAD Y AUDITORÍA - ISSUE #0
-- =====================================================

CREATE TABLE IF NOT EXISTS sys_usuario (
    id_usuario INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    id_asambleista INT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_asambleista)
        REFERENCES asambleista(id_asambleista)
        ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sys_rol (
    id_rol INT PRIMARY KEY AUTO_INCREMENT,
    nombre_rol VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sys_permiso (
    id_permiso INT PRIMARY KEY AUTO_INCREMENT,
    nombre_permiso VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT
);

CREATE TABLE IF NOT EXISTS sys_usuario_rol (
    id_usuario INT NOT NULL,
    id_rol INT NOT NULL,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id_usuario, id_rol),

    FOREIGN KEY (id_usuario)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE CASCADE,

    FOREIGN KEY (id_rol)
        REFERENCES sys_rol(id_rol)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sys_rol_permiso (
    id_rol INT NOT NULL,
    id_permiso INT NOT NULL,

    PRIMARY KEY (id_rol, id_permiso),

    FOREIGN KEY (id_rol)
        REFERENCES sys_rol(id_rol)
        ON DELETE CASCADE,

    FOREIGN KEY (id_permiso)
        REFERENCES sys_permiso(id_permiso)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sys_log_auditoria (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_usuario INT NULL,
    accion VARCHAR(100) NOT NULL,
    tabla_afectada VARCHAR(100),
    detalle TEXT,
    ip_origen VARCHAR(45),
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_usuario)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE SET NULL
);

-- Variable para simular usuario activo en auditoría
SET @usuario_actual = 1;


-- =====================================================
-- 4. NORMATIVA - ISSUE #10
-- Jerarquía de Reglamentos / Estructura Recursiva
-- =====================================================

CREATE TABLE IF NOT EXISTS reglamento (
    id_reglamento INT PRIMARY KEY AUTO_INCREMENT,
    nombre_normativa VARCHAR(200) NOT NULL,
    sigla VARCHAR(20) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS elemento_normativo (
    id_elemento INT PRIMARY KEY AUTO_INCREMENT,
    id_reglamento INT NOT NULL,
    id_elemento_padre INT NULL,
    id_nivel_reglamento INT NOT NULL,
    numero_etiqueta VARCHAR(20) NOT NULL,
    contenido_texto TEXT NOT NULL,
    orden INT NOT NULL,
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE NULL,
    id_estado_vigencia INT NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario_registro INT NOT NULL,

    id_elemento_padre_normalizado INT 
        GENERATED ALWAYS AS (COALESCE(id_elemento_padre, 0)) STORED,

    vigente_unico INT 
        GENERATED ALWAYS AS (
            CASE 
                WHEN id_estado_vigencia = 1 AND fecha_fin_vigencia IS NULL THEN 1
                ELSE NULL
            END
        ) STORED,

    INDEX idx_elemento_reglamento (id_reglamento),
    INDEX idx_elemento_padre (id_elemento_padre),
    INDEX idx_elemento_vigencia (fecha_inicio_vigencia, fecha_fin_vigencia),
    INDEX idx_elemento_orden (id_reglamento, orden),
    INDEX idx_elemento_etiqueta (numero_etiqueta),
    INDEX idx_elemento_estado (id_estado_vigencia),

    CONSTRAINT fk_elemento_reglamento 
        FOREIGN KEY (id_reglamento) 
        REFERENCES reglamento(id_reglamento) 
        ON DELETE RESTRICT,

    CONSTRAINT fk_elemento_padre 
        FOREIGN KEY (id_elemento_padre) 
        REFERENCES elemento_normativo(id_elemento) 
        ON DELETE RESTRICT,

    CONSTRAINT fk_elemento_nivel 
        FOREIGN KEY (id_nivel_reglamento) 
        REFERENCES catalogo_nivel_reglamento(id_nivel_reglamento),

    CONSTRAINT fk_elemento_estado_vigencia 
        FOREIGN KEY (id_estado_vigencia) 
        REFERENCES catalogo_estado_vigencia(id_estado_vigencia),

    CONSTRAINT fk_elemento_usuario 
        FOREIGN KEY (id_usuario_registro) 
        REFERENCES sys_usuario(id_usuario),

    CONSTRAINT chk_fechas_vigencia 
        CHECK (fecha_fin_vigencia IS NULL OR fecha_inicio_vigencia <= fecha_fin_vigencia),

    CONSTRAINT chk_orden_positivo 
        CHECK (orden > 0),

    CONSTRAINT uq_elemento_vigente UNIQUE (
        id_reglamento,
        id_elemento_padre_normalizado,
        numero_etiqueta,
        vigente_unico
    )
);

-- -----------------------------------------------------
-- FUNCIONES DE CONSULTA DE NORMATIVA
-- -----------------------------------------------------

DROP FUNCTION IF EXISTS obtener_ruta_elemento;

DELIMITER //

CREATE FUNCTION obtener_ruta_elemento(p_id_elemento INT)
RETURNS VARCHAR(500)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE ruta VARCHAR(500);

    WITH RECURSIVE ruta_cte AS (
        SELECT 
            id_elemento, 
            numero_etiqueta, 
            id_elemento_padre, 
            1 AS nivel
        FROM elemento_normativo
        WHERE id_elemento = p_id_elemento

        UNION ALL

        SELECT 
            e.id_elemento, 
            e.numero_etiqueta, 
            e.id_elemento_padre, 
            r.nivel + 1 AS nivel
        FROM elemento_normativo e
        INNER JOIN ruta_cte r 
            ON e.id_elemento = r.id_elemento_padre
    )
    SELECT GROUP_CONCAT(numero_etiqueta ORDER BY nivel DESC SEPARATOR ' > ')
    INTO ruta
    FROM ruta_cte;

    RETURN COALESCE(ruta, '');
END //

DELIMITER ;


-- =====================================================
-- 5. NOMBRAMIENTOS - ISSUE #14
-- Historial de Nombramientos
-- =====================================================

CREATE TABLE IF NOT EXISTS nombramiento (
    id_nombramiento INT PRIMARY KEY AUTO_INCREMENT,
    id_asambleista INT NOT NULL,
    id_sector INT NOT NULL,
    id_puesto INT NOT NULL,
    resolucion_id INT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    estado VARCHAR(20) DEFAULT 'Activo',
    id_usuario_registro INT NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,

    INDEX idx_nombramiento_asambleista (id_asambleista),
    INDEX idx_nombramiento_sector (id_sector),
    INDEX idx_nombramiento_fechas (fecha_inicio, fecha_fin),
    INDEX idx_nombramiento_estado (estado),

    CONSTRAINT fk_nombramiento_asambleista 
        FOREIGN KEY (id_asambleista) 
        REFERENCES asambleista(id_asambleista) 
        ON DELETE CASCADE,

    CONSTRAINT fk_nombramiento_sector 
        FOREIGN KEY (id_sector) 
        REFERENCES catalogo_sector(id_sector),

    CONSTRAINT fk_nombramiento_puesto 
        FOREIGN KEY (id_puesto) 
        REFERENCES catalogo_puestos(id_puesto),

    CONSTRAINT fk_nombramiento_usuario 
        FOREIGN KEY (id_usuario_registro) 
        REFERENCES sys_usuario(id_usuario),

    CONSTRAINT chk_fechas_nombramiento 
        CHECK (fecha_fin IS NULL OR fecha_inicio <= fecha_fin)
);

DROP VIEW IF EXISTS v_historial_nombramientos;
CREATE OR REPLACE VIEW v_historial_nombramientos AS
SELECT 
    n.id_nombramiento,
    a.nombre AS asambleista,
    a.cedula,
    s.nombre AS sector,
    p.nombre_puesto AS puesto,
    n.fecha_inicio,
    n.fecha_fin,
    n.estado,
    CASE 
        WHEN n.fecha_fin IS NULL AND n.estado = 'Activo' THEN 'Vigente'
        WHEN n.fecha_fin < CURDATE() THEN 'Vencido'
        ELSE n.estado
    END AS estado_real,
    n.observaciones,
    u.username AS registrado_por,
    n.fecha_registro
FROM nombramiento n
INNER JOIN asambleista a ON n.id_asambleista = a.id_asambleista
INNER JOIN catalogo_sector s ON n.id_sector = s.id_sector
INNER JOIN catalogo_puestos p ON n.id_puesto = p.id_puesto
INNER JOIN sys_usuario u ON n.id_usuario_registro = u.id_usuario
ORDER BY n.fecha_inicio DESC;

-- -----------------------------------------------------
-- SP Y TRIGGER PARA VALIDAR TRASLAPE DE NOMBRAMIENTOS
-- -----------------------------------------------------

DROP PROCEDURE IF EXISTS sp_registrar_nombramiento;

DELIMITER //

CREATE PROCEDURE sp_registrar_nombramiento(
    IN p_id_asambleista INT,
    IN p_id_sector INT,
    IN p_id_puesto INT,
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_id_usuario_registro INT,
    IN p_observaciones TEXT
)
BEGIN
    IF EXISTS (
        SELECT 1
        FROM nombramiento
        WHERE id_asambleista = p_id_asambleista
          AND id_sector = p_id_sector
          AND estado = 'Activo'
          AND (
              p_fecha_inicio <= COALESCE(fecha_fin, '9999-12-31')
              AND COALESCE(p_fecha_fin, '9999-12-31') >= fecha_inicio
          )
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: ya existe un nombramiento activo traslapado para este asambleísta y sector.';
    END IF;

    INSERT INTO nombramiento (
        id_asambleista, id_sector, id_puesto, fecha_inicio, fecha_fin,
        estado, id_usuario_registro, observaciones
    )
    VALUES (
        p_id_asambleista, p_id_sector, p_id_puesto, p_fecha_inicio, p_fecha_fin,
        'Activo', p_id_usuario_registro, p_observaciones
    );
END //

DELIMITER ;


-- =====================================================
-- 6. REFORMAS Y VERSIONAMIENTO - ISSUE #15
-- =====================================================

CREATE TABLE IF NOT EXISTS reforma_aplicada (
    id_reforma INT PRIMARY KEY AUTO_INCREMENT,
    id_resolucion INT NULL,
    id_elemento_normativo INT NOT NULL,
    texto_anterior TEXT NOT NULL,
    texto_nuevo TEXT NOT NULL,
    fecha_inicio_vigencia DATE NOT NULL,
    id_tipo_reforma INT NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario_registro INT NOT NULL,

    INDEX idx_reforma_elemento (id_elemento_normativo),
    INDEX idx_reforma_fecha (fecha_inicio_vigencia),
    INDEX idx_reforma_tipo (id_tipo_reforma),

    CONSTRAINT fk_reforma_elemento
        FOREIGN KEY (id_elemento_normativo)
        REFERENCES elemento_normativo(id_elemento)
        ON DELETE RESTRICT,

    CONSTRAINT fk_reforma_tipo
        FOREIGN KEY (id_tipo_reforma)
        REFERENCES catalogo_tipo_reforma(id_tipo_reforma)
        ON DELETE RESTRICT,

    CONSTRAINT fk_reforma_usuario
        FOREIGN KEY (id_usuario_registro)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE RESTRICT
);


-- --------------------------
-- TRIGGER
-- --------------------------

DROP TRIGGER IF EXISTS tg_vigencia_normativa;

DELIMITER //

CREATE TRIGGER tg_vigencia_normativa
AFTER INSERT ON reforma_aplicada
FOR EACH ROW
BEGIN
    DECLARE v_existe INT;

    SELECT COUNT(*)
    INTO v_existe
    FROM elemento_normativo
    WHERE id_elemento = NEW.id_elemento_normativo
      AND id_estado_vigencia = 1
      AND fecha_fin_vigencia IS NULL;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede reformar un elemento que no está vigente.';
    END IF;

    UPDATE elemento_normativo
    SET 
        id_estado_vigencia = 2,
        fecha_fin_vigencia = DATE_SUB(NEW.fecha_inicio_vigencia, INTERVAL 1 DAY)
    WHERE id_elemento = NEW.id_elemento_normativo
      AND id_estado_vigencia = 1
      AND fecha_fin_vigencia IS NULL;

    INSERT INTO elemento_normativo (
        id_reglamento,
        id_elemento_padre,
        id_nivel_reglamento,
        numero_etiqueta,
        contenido_texto,
        orden,
        fecha_inicio_vigencia,
        fecha_fin_vigencia,
        id_estado_vigencia,
        id_usuario_registro
    )
    SELECT 
        id_reglamento,
        id_elemento_padre,
        id_nivel_reglamento,
        numero_etiqueta,
        NEW.texto_nuevo,
        orden,
        NEW.fecha_inicio_vigencia,
        NULL,
        1,
        NEW.id_usuario_registro
    FROM elemento_normativo
    WHERE id_elemento = NEW.id_elemento_normativo;
END //

DELIMITER ;

-- --------------------
-- FUNCIÓN
-- --------------------

DROP FUNCTION IF EXISTS obtener_elemento_vigente;

DELIMITER //

CREATE FUNCTION obtener_elemento_vigente(
    p_id_reglamento INT,
    p_numero_etiqueta VARCHAR(20),
    p_id_elemento_padre INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_id_elemento INT;

    SELECT id_elemento
    INTO v_id_elemento
    FROM elemento_normativo
    WHERE id_reglamento = p_id_reglamento
      AND numero_etiqueta = p_numero_etiqueta
      AND COALESCE(id_elemento_padre, 0) = COALESCE(p_id_elemento_padre, 0)
      AND id_estado_vigencia = 1
      AND fecha_fin_vigencia IS NULL
    LIMIT 1;

    RETURN v_id_elemento;
END //

DELIMITER ;

-- -------------------------------------------
-- TRIGGERS DE AUDITORÍA
-- -------------------------------------------

DROP TRIGGER IF EXISTS trg_auditoria_asambleista_insert;
DROP TRIGGER IF EXISTS trg_auditoria_asambleista_update;
DROP TRIGGER IF EXISTS trg_auditoria_normativa_insert;
DROP TRIGGER IF EXISTS trg_auditoria_normativa_update;

DELIMITER //

CREATE TRIGGER trg_auditoria_asambleista_insert
AFTER INSERT ON asambleista
FOR EACH ROW
BEGIN
    INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
    VALUES (@usuario_actual, 'INSERT', 'asambleista', CONCAT('Se registró el asambleísta: ', NEW.nombre));
END //

CREATE TRIGGER trg_auditoria_asambleista_update
AFTER UPDATE ON asambleista
FOR EACH ROW
BEGIN
    INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
    VALUES (@usuario_actual, 'UPDATE', 'asambleista', CONCAT('Se actualizó el asambleísta ID: ', NEW.id_asambleista));
END //

CREATE TRIGGER trg_auditoria_normativa_insert
AFTER INSERT ON elemento_normativo
FOR EACH ROW
BEGIN
    INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
    VALUES (@usuario_actual, 'INSERT', 'elemento_normativo', CONCAT('Se creó el elemento normativo: ', NEW.numero_etiqueta));
END //

CREATE TRIGGER trg_auditoria_normativa_update
AFTER UPDATE ON elemento_normativo
FOR EACH ROW
BEGIN
    INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
    VALUES (@usuario_actual, 'UPDATE', 'elemento_normativo', CONCAT('Se actualizó el elemento normativo ID: ', NEW.id_elemento));
END //

CREATE TRIGGER trg_auditoria_asambleista_delete
AFTER DELETE ON asambleista
FOR EACH ROW
BEGIN
    INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
    VALUES (@usuario_actual, 'DELETE', 'asambleista', CONCAT('Se eliminó el asambleísta ID: ', OLD.id_asambleista, ' - ', OLD.nombre));
END //

DELIMITER ;


-- =====================================================
-- 7. DATOS INICIALES Y PRUEBAS
-- =====================================================

-- Catálogos
INSERT INTO catalogo_sector (nombre, descripcion) VALUES
('Docente', 'Representante del sector docente'),
('Administrativo', 'Personal administrativo'),
('Estudiantil', 'Representación estudiantil')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

INSERT INTO catalogo_puestos (nombre_puesto, descripcion) VALUES
('Propietario', 'Representante propietario'),
('Suplente', 'Representante suplente'),
('Presidente', 'Presidente del directorio')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

INSERT INTO catalogo_nivel_reglamento (nombre, orden) VALUES
('Título', 1),
('Capítulo', 2),
('Artículo', 3),
('Inciso', 4),
('Sub-inciso', 5)
ON DUPLICATE KEY UPDATE orden = VALUES(orden);

INSERT INTO catalogo_estado_vigencia (nombre, descripcion) VALUES
('Vigente', 'Versión activa actualmente'),
('Histórico', 'Versión anterior'),
('Derogado', 'Versión eliminada por reforma')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

INSERT INTO catalogo_tipo_reforma (nombre, descripcion) VALUES
('Modificación', 'Cambio de texto en un elemento normativo'),
('Derogación', 'Eliminación de una norma vigente'),
('Adición', 'Agrega nuevo contenido normativo')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

-- Roles y permisos
INSERT INTO sys_rol (nombre_rol, descripcion) VALUES
('Administrador', 'Control total del sistema'),
('Secretaria_AIR', 'Gestión de normativa y certificaciones'),
('Directorio', 'Planificación de sesiones'),
('Asambleísta', 'Consulta y creación de mociones'),
('Consulta', 'Solo lectura')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

INSERT INTO sys_permiso (nombre_permiso, descripcion) VALUES
('crear_mocion', 'Permite crear mociones'),
('certificar', 'Permite emitir certificaciones'),
('planificar', 'Permite organizar agenda'),
('editar_normativa', 'Permite crear y editar normativa'),
('consultar_normativa', 'Permite consultar normativa')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

-- Usuarios base para cada rol principal
INSERT INTO sys_usuario (username, password_hash, email, activo) VALUES
('admin', 'Admin123', 'admin@air.go.cr', TRUE),
('secretaria', 'Secretaria123', 'secretaria@air.go.cr', TRUE),
('asambleista_user', 'Asamblea123', 'asambleista@air.go.cr', TRUE)
ON DUPLICATE KEY UPDATE email = VALUES(email);

-- Asignación de roles
INSERT INTO sys_usuario_rol (id_usuario, id_rol)
SELECT u.id_usuario, r.id_rol
FROM sys_usuario u, sys_rol r
WHERE (u.username = 'admin'           AND r.nombre_rol = 'Administrador')
   OR (u.username = 'secretaria'      AND r.nombre_rol = 'Secretaria_AIR')
   OR (u.username = 'asambleista_user' AND r.nombre_rol = 'Asambleísta')
ON DUPLICATE KEY UPDATE fecha_asignacion = CURRENT_TIMESTAMP;

INSERT INTO sys_usuario (username, password_hash, email, activo) VALUES
('directorio01', 'Directorio123', 'directorio@air.go.cr', TRUE),
('consulta01',   'Consulta123',   'consulta@air.go.cr',   TRUE)
ON DUPLICATE KEY UPDATE email = VALUES(email);

INSERT INTO sys_usuario_rol (id_usuario, id_rol)
SELECT u.id_usuario, r.id_rol
FROM sys_usuario u, sys_rol r
WHERE (u.username = 'directorio01' AND r.nombre_rol = 'Directorio')
   OR (u.username = 'consulta01'   AND r.nombre_rol = 'Consulta')
ON DUPLICATE KEY UPDATE fecha_asignacion = CURRENT_TIMESTAMP;

-- Asambleístas
INSERT INTO asambleista (cedula, nombre, correo_institucional) VALUES
('1-2345-6789', 'Ana Rodríguez Mora', 'arodriguez@tec.ac.cr'),
('2-3456-7890', 'Carlos Jiménez Solano', 'cjimenez@tec.ac.cr')
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);

-- Prueba de bitácora
UPDATE asambleista
SET nombre = 'Ana María Rodríguez Mora'
WHERE cedula = '1-2345-6789';

-- Reglamentos
INSERT INTO reglamento (nombre_normativa, sigla, descripcion) VALUES
('Estatuto Orgánico del TEC', 'EO', 'Normativa principal institucional'),
('Reglamento de Enseñanza-Aprendizaje', 'REA', 'Reglamento académico')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

-- Elementos normativos de prueba
INSERT INTO elemento_normativo 
(id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta, contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
VALUES
(1, NULL, 1, 'I', 'Disposiciones Preliminares', 1, '2024-01-01', 1, 1),
(1, 1, 2, '1', 'De la Naturaleza Jurídica', 1, '2024-01-01', 1, 1),
(1, 2, 3, '1.1', 'Texto original del artículo 1.', 1, '2024-01-01', 1, 1);

-- Nombramientos
INSERT INTO nombramiento 
(id_asambleista, id_sector, id_puesto, resolucion_id, fecha_inicio, fecha_fin, estado, id_usuario_registro, observaciones)
VALUES
(1, 1, 1, NULL, '2024-01-15', NULL, 'Activo', 1, 'Nombramiento inicial'),
(2, 2, 2, NULL, '2024-02-01', '2024-12-31', 'Finalizado', 1, 'Nombramiento con fecha de fin');

-- Reforma de prueba
INSERT INTO reforma_aplicada 
(id_resolucion, id_elemento_normativo, texto_anterior, texto_nuevo, fecha_inicio_vigencia, id_tipo_reforma, id_usuario_registro)
VALUES
(NULL, 3, 'Texto original del artículo 1.', 'Texto reformado del artículo 1.', '2025-01-01', 1, 1);


-- =====================================================
-- 8. CONSULTAS DE VERIFICACIÓN
-- =====================================================

SELECT * FROM catalogo_sector;
SELECT * FROM catalogo_puestos;
SELECT * FROM sys_usuario;
SELECT * FROM sys_rol;
SELECT * FROM asambleista;
SELECT * FROM bitacora_asambleistas;
SELECT * FROM reglamento;
SELECT * FROM elemento_normativo;
SELECT * FROM v_historial_nombramientos;
SELECT * FROM reforma_aplicada;

-- Prueba de auditoría
SELECT * FROM sys_log_auditoria;

-- Prueba de usuarios por rol
SELECT 
    u.username,
    r.nombre_rol
FROM sys_usuario u
INNER JOIN sys_usuario_rol ur ON u.id_usuario = ur.id_usuario
INNER JOIN sys_rol r ON ur.id_rol = r.id_rol;

-- Prueba de SP de nombramientos (demostrar el error de traslape(choque de dos periodos de tiempo))
-- CALL sp_registrar_nombramiento(1, 1, 1, '2024-03-01', '2024-06-01', 1, 'Prueba de traslape');
