--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1. EL SCHEMA 
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- SCHEMA BASE - SPRINT 2 SEMANA 1
-- Fecha: 2026-05-08
-- Propósito: Tablas compartidas por Issues #0, #9 y #14
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1. CATÁLOGOS COMPARTIDOS (Usados por #9 y #14)
-- 

-- Catálogo de sectores (Docente, Estudiante, Administrativo, Egresado)
CREATE TABLE IF NOT EXISTS catalogo_sector (
    id_sector INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Catálogo de puestos (Representante, Secretario, Vocal, Presidente, Coordinador)
CREATE TABLE IF NOT EXISTS catalogo_puestos (
    id_puesto INT PRIMARY KEY AUTO_INCREMENT,
    nombre_puesto VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 
-- 2. TABLA DE ASAMBLEÍSTAS (Issue #9)
-- 

CREATE TABLE IF NOT EXISTS asambleista (
    asambleista_id INT PRIMARY KEY AUTO_INCREMENT,
    cedula VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    correo_institucional VARCHAR(100) UNIQUE NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bitácora de cambios de asambleístas (Issue #9)
CREATE TABLE IF NOT EXISTS bitacora_asambleistas (
    id_bitacora_asambleista INT PRIMARY KEY AUTO_INCREMENT,
    asambleista_id INT NOT NULL,
    cedula_anterior VARCHAR(20),
    nombre_anterior VARCHAR(150),
    razon_cambio VARCHAR(255),
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (asambleista_id) REFERENCES asambleista(asambleista_id) ON DELETE CASCADE
);

-- 
-- 3. TABLAS DE SEGURIDAD (Issue #0 - Mínimo para funcionar)
-- 

-- Usuarios del sistema
CREATE TABLE IF NOT EXISTS sys_usuario (
    id_usuario INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    asambleista_id INT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (asambleista_id) REFERENCES asambleista(asambleista_id) ON DELETE SET NULL
);

-- Roles de usuario
CREATE TABLE IF NOT EXISTS sys_rol (
    id_rol INT PRIMARY KEY AUTO_INCREMENT,
    nombre_rol VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Relación usuario - rol
CREATE TABLE IF NOT EXISTS sys_usuario_rol (
    id_usuario INT NOT NULL,
    id_rol INT NOT NULL,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_usuario, id_rol),
    FOREIGN KEY (id_usuario) REFERENCES sys_usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_rol) REFERENCES sys_rol(id_rol) ON DELETE CASCADE
);

-- 
-- 4. DATOS INICIALES MÍNIMOS (Para que todo funcione)
-- 

-- Insertar roles base (Issue #0)
INSERT INTO sys_rol (nombre_rol, descripcion) VALUES 
    ('Administrador', 'Control total del sistema'),
    ('Secretaria_AIR', 'Editor - gestión de sesiones y certificaciones'),
    ('Consulta', 'Solo lectura - compilador y búsquedas')
ON DUPLICATE KEY UPDATE nombre_rol = VALUES(nombre_rol);

-- Insertar sectores base (Issue #9 y #14)
INSERT INTO catalogo_sector (nombre, descripcion) VALUES 
    ('Docente', 'Representante del sector docente'),
    ('Estudiante', 'Representación estudiantil'),
    ('Administrativo', 'Personal administrativo'),
    ('Egresado', 'Representación de egresados')
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);

-- Insertar puestos base (Issue #14)
INSERT INTO catalogo_puestos (nombre_puesto, descripcion) VALUES 
    ('Representante', 'Representante titular'),
    ('Secretario', 'Secretario de la comisión'),
    ('Vocal', 'Vocal de la comisión'),
    ('Presidente', 'Presidente del directorio'),
    ('Coordinador', 'Coordinador de comisión')
ON DUPLICATE KEY UPDATE nombre_puesto = VALUES(nombre_puesto);

-- Insertar usuario administrador por defecto (Issue #0)
-- Contraseña: Admin123! (cambiar después en producción)
INSERT INTO sys_usuario (username, password_hash, email, activo) VALUES 
    ('admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin@air.go.cr', 1)
ON DUPLICATE KEY UPDATE username = VALUES(username);

-- Asignar rol administrador al usuario admin
INSERT INTO sys_usuario_rol (id_usuario, id_rol) VALUES (1, 1)
ON DUPLICATE KEY UPDATE id_usuario = VALUES(id_usuario);

-- FIN DEL SCHEMA BASE - SEMANA 1 sprint 2
-- 


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Aquí va lo que ustedes hicieron antes : catalogo_sector, catalogo_puestos,
-- asambleista, bitacora_asambleistas, sys_usuario, sys_rol, sys_usuario_rol...
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--ISSUE #0 - SEGURIDAD Y AUDITORÍA
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CREATE TABLE IF NOT EXISTS sys_permiso (
    id_permiso INT PRIMARY KEY AUTO_INCREMENT,
    nombre_permiso VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT
);

CREATE TABLE IF NOT EXISTS sys_rol_permiso (
    id_rol INT NOT NULL,
    id_permiso INT NOT NULL,
    PRIMARY KEY (id_rol, id_permiso),
    FOREIGN KEY (id_rol) REFERENCES sys_rol(id_rol) ON DELETE CASCADE,
    FOREIGN KEY (id_permiso) REFERENCES sys_permiso(id_permiso) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sys_log_auditoria (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_usuario INT NULL,
    accion VARCHAR(100) NOT NULL, -- 'LOGIN_EXITOSO', 'LOGIN_FALLIDO', 'LOGOUT'
    detalle TEXT,
    ip_origen VARCHAR(45),
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES sys_usuario(id_usuario) ON DELETE SET NULL
);

INSERT INTO sys_rol (nombre_rol, descripcion) VALUES 
    ('Directorio', 'Lectura y planificación de sesiones'),
    ('Asambleísta', 'Consulta y creación de mociones')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

INSERT INTO sys_permiso (nombre_permiso, descripcion) VALUES 
    ('crear_mocion', 'Permite a los asambleístas proponer mociones'),
    ('certificar', 'Permite a secretaría emitir PDFs oficiales'),
    ('planificar', 'Permite al directorio organizar la agenda');