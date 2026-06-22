-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- COMPLEMENTO al schema.sql ISSUE #0 - SEGURIDAD, ROLES Y AUDITORÍA
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- 1. Tabla de Permisos (Control de acciones específicas)
CREATE TABLE IF NOT EXISTS sys_permiso (
    id_permiso INT PRIMARY KEY AUTO_INCREMENT,
    nombre_permiso VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT
);

-- 2. Relación Rol - Permiso
CREATE TABLE IF NOT EXISTS sys_rol_permiso (
    id_rol INT NOT NULL,
    id_permiso INT NOT NULL,
    PRIMARY KEY (id_rol, id_permiso),
    FOREIGN KEY (id_rol) REFERENCES sys_rol(id_rol) ON DELETE CASCADE,
    FOREIGN KEY (id_permiso) REFERENCES sys_permiso(id_permiso) ON DELETE CASCADE
);

-- 3. Bitácora de Auditoría (REQUERIMIENTO: Registro de login/fallos)
CREATE TABLE IF NOT EXISTS sys_log_auditoria (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_usuario INT NULL,
    accion VARCHAR(100) NOT NULL, -- 'LOGIN_EXITOSO', 'LOGIN_FALLIDO', 'LOGOUT'
    detalle TEXT,
    ip_origen VARCHAR(45),
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES sys_usuario(id_usuario) ON DELETE SET NULL
);

-- 4. Inserción de Roles faltantes según requerimientos
INSERT INTO sys_rol (nombre_rol, descripcion) VALUES 
    ('Directorio', 'Lectura y planificación de sesiones'),
    ('Asambleísta', 'Consulta y creación de mociones')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);

-- 5. Inserción de permisos básicos
INSERT INTO sys_permiso (nombre_permiso, descripcion) VALUES 
    ('crear_mocion', 'Permite a los asambleístas proponer mociones'),
    ('certificar', 'Permite a secretaría emitir PDFs oficiales'),
    ('planificar', 'Permite al directorio organizar la agenda');
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion);
SELECT * FROM sys_rol;