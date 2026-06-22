-- :::::::::::::::::::::::::::::::::::::::::::::::::::
-- ISSUE #9 - Catálogo de Asambleístas
-- Autora: María Fernanda Vargas Guzmán
-- Sprint 2 - Semana 1 y 2
-- :::::::::::::::::::::::::::::::::::::::::::::::::::

-- Drops
DROP TABLE IF EXISTS bitacora_asambleistas;
DROP TABLE IF EXISTS nombramiento;
DROP TABLE IF EXISTS asambleista;

-- Tabla principal de asambleístas
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

-- Tabla de nombramientos
CREATE TABLE nombramiento (
    id_nombramiento INT AUTO_INCREMENT PRIMARY KEY,

    id_asambleista INT NOT NULL,
    id_sector INT NOT NULL,
    id_puesto INT NOT NULL,

    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,

    estado VARCHAR(30) NOT NULL,

    FOREIGN KEY (id_asambleista)
        REFERENCES asambleista(id_asambleista)
        ON DELETE CASCADE,

    FOREIGN KEY (id_sector)
        REFERENCES catalogo_sector(id_sector),

    FOREIGN KEY (id_puesto)
        REFERENCES catalogo_puestos(id_puesto),

    CONSTRAINT chk_fechas_nombramiento
    CHECK (
        fecha_fin IS NULL
        OR fecha_fin >= fecha_inicio
    )
);

-- Bitácora para registrar cambios en datos personales
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

-- Trigger para registrar cambios automáticamente en la bitácora
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

-- Datos de prueba válidos

-- para catálogo:
INSERT INTO catalogo_sector (nombre)
VALUES 
('Docente'),
('Administrativo'),
('Estudiantil');

INSERT INTO catalogo_puestos (nombre_puesto)
VALUES 
('Propietario'),
('Suplente');

-- para asambleista:
INSERT INTO asambleista (cedula, nombre, correo_institucional)
VALUES 
('1-2345-6789', 'Ana Rodríguez Mora', 'arodriguez@tec.ac.cr'),
('2-3456-7890', 'Carlos Jiménez Solano', 'cjimenez@tec.ac.cr');

-- Prueba de edición para generar registro en bitácora
UPDATE asambleista
SET nombre = 'Ana María Rodríguez Mora'
WHERE cedula = '1-2345-6789';

-- Consultas de prueba
SELECT * FROM asambleista;
SELECT * FROM bitacora_asambleistas;
