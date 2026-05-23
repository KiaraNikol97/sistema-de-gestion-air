-- =====================================================
-- SISTEMA DE GESTIÓN AIR
-- Sprint 2 - Semana 2
-- =====================================================

-- Parte 1:

DROP DATABASE IF EXISTS proyecto_air;
CREATE DATABASE proyecto_air;
USE proyecto_air;

-- =====================================================
-- 1. CATÁLOGOS COMPARTIDOS
-- =====================================================

CREATE TABLE catalogo_sector (
    id_sector INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE catalogo_puestos (
    id_puesto INT PRIMARY KEY AUTO_INCREMENT,
    nombre_puesto VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE catalogo_nivel_reglamento (
    id_nivel_reglamento INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    orden INT NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE catalogo_estado_vigencia (
    id_estado_vigencia INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT
);

CREATE TABLE catalogo_tipo_reforma (
    id_tipo_reforma INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT
);

-- =====================================================
-- 2. ASAMBLEÍSTAS - ISSUE #9
-- =====================================================

CREATE TABLE asambleista (
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

CREATE TABLE bitacora_asambleistas (
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

-- =====================================================
-- 3. SEGURIDAD Y AUDITORÍA - ISSUE #0
-- =====================================================

CREATE TABLE sys_usuario (
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

CREATE TABLE sys_rol (
    id_rol INT PRIMARY KEY AUTO_INCREMENT,
    nombre_rol VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sys_permiso (
    id_permiso INT PRIMARY KEY AUTO_INCREMENT,
    nombre_permiso VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT
);

CREATE TABLE sys_usuario_rol (
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

CREATE TABLE sys_rol_permiso (
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

CREATE TABLE sys_log_auditoria (
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

-- =====================================================
-- 4. NORMATIVA - ISSUE #10
-- =====================================================

CREATE TABLE reglamento (
    id_reglamento INT PRIMARY KEY AUTO_INCREMENT,
    nombre_normativa VARCHAR(200) NOT NULL,
    sigla VARCHAR(20) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE elemento_normativo (
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

-- =====================================================
-- 5. NOMBRAMIENTOS - ISSUE #14
-- =====================================================

CREATE TABLE nombramiento (
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

CREATE VIEW v_historial_nombramientos AS
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
INNER JOIN sys_usuario u ON n.id_usuario_registro = u.id_usuario;

-- =====================================================
-- 6. REFORMAS Y VERSIONAMIENTO - ISSUE #15
-- =====================================================

CREATE TABLE reforma_aplicada (
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

-- =====================================================
-- 7. DATOS INICIALES
-- =====================================================

INSERT INTO catalogo_sector (nombre, descripcion) VALUES
('Docente', 'Representante del sector docente'),
('Administrativo', 'Personal administrativo'),
('Estudiantil', 'Representación estudiantil');

INSERT INTO catalogo_puestos (nombre_puesto, descripcion) VALUES
('Propietario', 'Representante propietario'),
('Suplente', 'Representante suplente'),
('Presidente', 'Presidente del directorio');

INSERT INTO catalogo_nivel_reglamento (nombre, orden) VALUES
('Título', 1),
('Capítulo', 2),
('Artículo', 3),
('Inciso', 4),
('Sub-inciso', 5);

INSERT INTO catalogo_estado_vigencia (nombre, descripcion) VALUES
('Vigente', 'Versión activa actualmente'),
('Histórico', 'Versión anterior'),
('Derogado', 'Versión eliminada por reforma');

INSERT INTO catalogo_tipo_reforma (nombre, descripcion) VALUES
('Modificación', 'Cambio de texto en un elemento normativo'),
('Derogación', 'Eliminación de una norma vigente'),
('Adición', 'Agrega nuevo contenido normativo');

INSERT INTO sys_rol (nombre_rol, descripcion) VALUES
('Administrador', 'Control total del sistema'),
('Secretaria_AIR', 'Gestión de normativa y certificaciones'),
('Directorio', 'Planificación de sesiones'),
('Asambleísta', 'Consulta y creación de mociones'),
('Consulta', 'Solo lectura');

INSERT INTO sys_permiso (nombre_permiso, descripcion) VALUES
('crear_mocion', 'Permite crear mociones'),
('certificar', 'Permite emitir certificaciones'),
('planificar', 'Permite organizar agenda'),
('editar_normativa', 'Permite crear y editar normativa'),
('consultar_normativa', 'Permite consultar normativa');

INSERT INTO sys_usuario (username, password_hash, email, activo) VALUES
('admin', 'Admin123', 'admin@air.go.cr', TRUE),
('secretaria', 'Secretaria123', 'secretaria@air.go.cr', TRUE),
('asambleista_user', 'Asamblea123', 'asambleista@air.go.cr', TRUE),
('directorio01', 'Directorio123', 'directorio@air.go.cr', TRUE),
('consulta01', 'Consulta123', 'consulta@air.go.cr', TRUE);

INSERT INTO sys_usuario_rol (id_usuario, id_rol)
SELECT u.id_usuario, r.id_rol
FROM sys_usuario u, sys_rol r
WHERE (u.username = 'admin' AND r.nombre_rol = 'Administrador')
   OR (u.username = 'secretaria' AND r.nombre_rol = 'Secretaria_AIR')
   OR (u.username = 'asambleista_user' AND r.nombre_rol = 'Asambleísta')
   OR (u.username = 'directorio01' AND r.nombre_rol = 'Directorio')
   OR (u.username = 'consulta01' AND r.nombre_rol = 'Consulta');

INSERT INTO asambleista (cedula, nombre, correo_institucional) VALUES
('1-2345-6789', 'Ana Rodríguez Mora', 'arodriguez@tec.ac.cr'),
('2-3456-7890', 'Carlos Jiménez Solano', 'cjimenez@tec.ac.cr');

-- Simulación de bitácora de cambio de asambleísta en TiDB
UPDATE asambleista
SET nombre = 'Ana María Rodríguez Mora'
WHERE cedula = '1-2345-6789';

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
    1,
    '1-2345-6789',
    '1-2345-6789',
    'Ana Rodríguez Mora',
    'Ana María Rodríguez Mora',
    'arodriguez@tec.ac.cr',
    'arodriguez@tec.ac.cr',
    'Actualización de datos personales del asambleísta'
);

INSERT INTO reglamento (nombre_normativa, sigla, descripcion) VALUES
('Estatuto Orgánico del TEC', 'EO', 'Normativa principal institucional'),
('Reglamento de Enseñanza-Aprendizaje', 'REA', 'Reglamento académico');

INSERT INTO elemento_normativo 
(id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta, contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
VALUES
(1, NULL, 1, 'I', 'Disposiciones Preliminares', 1, '2024-01-01', 1, 1),
(1, 1, 2, '1', 'De la Naturaleza Jurídica', 1, '2024-01-01', 1, 1),
(1, 2, 3, '1.1', 'Texto original del artículo 1.', 1, '2024-01-01', 1, 1);

INSERT INTO nombramiento 
(id_asambleista, id_sector, id_puesto, resolucion_id, fecha_inicio, fecha_fin, estado, id_usuario_registro, observaciones)
VALUES
(1, 1, 1, NULL, '2024-01-15', NULL, 'Activo', 1, 'Nombramiento inicial'),
(2, 2, 2, NULL, '2024-02-01', '2024-12-31', 'Finalizado', 1, 'Nombramiento con fecha de fin');

-- Simulación de versionamiento en TiDB
UPDATE elemento_normativo
SET id_estado_vigencia = 2,
    fecha_fin_vigencia = '2024-12-31'
WHERE id_elemento = 3;

INSERT INTO elemento_normativo 
(id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta, contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
VALUES
(1, 2, 3, '1.1', 'Texto reformado del artículo 1.', 1, '2025-01-01', 1, 1);

INSERT INTO reforma_aplicada 
(id_resolucion, id_elemento_normativo, texto_anterior, texto_nuevo, fecha_inicio_vigencia, id_tipo_reforma, id_usuario_registro)
VALUES
(NULL, 3, 'Texto original del artículo 1.', 'Texto reformado del artículo 1.', '2025-01-01', 1, 1);

INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
VALUES
(1, 'UPDATE', 'asambleista', 'Actualización de nombre de Ana Rodríguez Mora'),
(1, 'UPDATE', 'elemento_normativo', 'Artículo 1.1 pasó de Vigente a Histórico'),
(1, 'INSERT', 'elemento_normativo', 'Se creó nueva versión vigente del artículo 1.1');

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
SELECT * FROM sys_log_auditoria;

SELECT 
    u.username,
    r.nombre_rol
FROM sys_usuario u
INNER JOIN sys_usuario_rol ur ON u.id_usuario = ur.id_usuario
INNER JOIN sys_rol r ON ur.id_rol = r.id_rol;



-- Parte 2 (ejecutarla por aparte en TiDB):

-- =====================================================
-- PRUEBA 1: Jerarquía normativa
-- =====================================================

SELECT 
    hijo.id_elemento,
    hijo.numero_etiqueta,
    hijo.contenido_texto,
    padre.numero_etiqueta AS etiqueta_padre,
    padre.contenido_texto AS texto_padre
FROM elemento_normativo hijo
LEFT JOIN elemento_normativo padre 
    ON hijo.id_elemento_padre = padre.id_elemento;

-- =====================================================
-- PRUEBA 2: Verificar versión histórica y vigente
-- =====================================================

SELECT 
    id_elemento,
    numero_etiqueta,
    contenido_texto,
    fecha_inicio_vigencia,
    fecha_fin_vigencia,
    id_estado_vigencia
FROM elemento_normativo
WHERE numero_etiqueta = '1.1'
ORDER BY fecha_inicio_vigencia;

-- =====================================================
-- PRUEBA 3: Detectar traslape de nombramiento
-- =====================================================

SELECT 
    COUNT(*) AS cantidad_traslapes
FROM nombramiento
WHERE id_asambleista = 1
  AND id_sector = 1
  AND estado = 'Activo'
  AND '2024-03-01' <= COALESCE(fecha_fin, '9999-12-31')
  AND '2024-06-01' >= fecha_inicio;

-- =====================================================
-- PRUEBA 4: Usuarios por rol
-- =====================================================

SELECT 
    u.username,
    r.nombre_rol
FROM sys_usuario u
INNER JOIN sys_usuario_rol ur ON u.id_usuario = ur.id_usuario
INNER JOIN sys_rol r ON ur.id_rol = r.id_rol;

-- =====================================================
-- PRUEBA 5: Auditoría
-- =====================================================

SELECT * FROM sys_log_auditoria;


-- =====================================================
-- TRIGGERS DE AUDITORÍA (Issue #13)
-- =====================================================

-- Trigger para INSERT en asambleista
DELIMITER //
CREATE TRIGGER tg_auditoria_asambleista_insert
AFTER INSERT ON asambleista
FOR EACH ROW
BEGIN
    INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
    VALUES (@current_user_id, 'INSERT', 'asambleista', CONCAT('Nuevo asambleísta: ', NEW.nombre, ' (', NEW.cedula, ')'));
END//
DELIMITER ;

-- Trigger para UPDATE en asambleista
DELIMITER //
CREATE TRIGGER tg_auditoria_asambleista_update
AFTER UPDATE ON asambleista
FOR EACH ROW
BEGIN
    DECLARE cambio VARCHAR(500);
    SET cambio = CONCAT('ID ', NEW.id_asambleista, ': ');
    
    IF OLD.nombre != NEW.nombre THEN
        SET cambio = CONCAT(cambio, 'nombre "', OLD.nombre, '" → "', NEW.nombre, '" ');
    END IF;
    IF OLD.cedula != NEW.cedula THEN
        SET cambio = CONCAT(cambio, 'cédula "', OLD.cedula, '" → "', NEW.cedula, '" ');
    END IF;
    
    INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
    VALUES (@current_user_id, 'UPDATE', 'asambleista', cambio);
END//
DELIMITER ;

-- Trigger para DELETE en asambleista
DELIMITER //
CREATE TRIGGER tg_auditoria_asambleista_delete
AFTER DELETE ON asambleista
FOR EACH ROW
BEGIN
    INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
    VALUES (@current_user_id, 'DELETE', 'asambleista', CONCAT('Eliminado asambleísta: ', OLD.nombre, ' (', OLD.cedula, ')'));
END//
DELIMITER ;

-- Trigger para INSERT en elemento_normativo
DELIMITER //
CREATE TRIGGER tg_auditoria_normativa_insert
AFTER INSERT ON elemento_normativo
FOR EACH ROW
BEGIN
    INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
    VALUES (@current_user_id, 'INSERT', 'elemento_normativo', CONCAT('Nuevo elemento: ', NEW.numero_etiqueta));
END//
DELIMITER ;

-- Trigger para UPDATE en elemento_normativo
DELIMITER //
CREATE TRIGGER tg_auditoria_normativa_update
AFTER UPDATE ON elemento_normativo
FOR EACH ROW
BEGIN
    IF OLD.contenido_texto != NEW.contenido_texto THEN
        INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
        VALUES (@current_user_id, 'UPDATE', 'elemento_normativo', CONCAT('Actualizado elemento ', NEW.numero_etiqueta));
    END IF;
END//
DELIMITER ;

-- Trigger para INSERT en nombramiento
DELIMITER //
CREATE TRIGGER tg_auditoria_nombramientos_insert
AFTER INSERT ON nombramiento
FOR EACH ROW
BEGIN
    INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
    VALUES (@current_user_id, 'INSERT', 'nombramiento', CONCAT('Nuevo nombramiento para asambleísta ID ', NEW.id_asambleista));
END//
DELIMITER ;

-- Trigger para UPDATE en nombramiento
DELIMITER //
CREATE TRIGGER tg_auditoria_nombramientos_update
AFTER UPDATE ON nombramiento
FOR EACH ROW
BEGIN
    IF OLD.estado != NEW.estado AND NEW.estado = 'Finalizado' THEN
        INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle)
        VALUES (@current_user_id, 'UPDATE', 'nombramiento', CONCAT('Finalizado nombramiento ID ', NEW.id_nombramiento));
    END IF;
END//
DELIMITER ;

-- Variable de sesión para usuario actual
SET @current_user_id = 1;