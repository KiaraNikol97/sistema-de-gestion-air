CREATE DATABASE IF NOT EXISTS proyecto_air;
USE proyecto_air;

-- ::::::::::::::::::::
-- Tablas de Catálogos
-- ::::::::::::::::::::

CREATE TABLE catalogo_sector (
    id_sector INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE catalogo_puestos (
    id_puesto INT AUTO_INCREMENT PRIMARY KEY,
    nombre_puesto VARCHAR(100) NOT NULL UNIQUE
);


-- :::::::::::::::::::::::::::::
-- feature/issue-9-asambleistas 
-- :::::::::::::::::::::::::::::

-- Asambleista:
CREATE TABLE asambleista (
    id_asambleista INT AUTO_INCREMENT PRIMARY KEY,
    cedula VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    correo_institucional VARCHAR(150)
);


-- Nombramiento:
CREATE TABLE nombramiento (
    id_nombramiento INT AUTO_INCREMENT PRIMARY KEY,
    id_asambleista INT NOT NULL,
    id_sector INT NOT NULL,
    id_puesto INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    estado VARCHAR(30) NOT NULL,

    FOREIGN KEY (id_asambleista) REFERENCES asambleista(id_asambleista),
    FOREIGN KEY (id_sector) REFERENCES catalogo_sector(id_sector),
    FOREIGN KEY (id_puesto) REFERENCES catalogo_puestos(id_puesto)
);


-- Bitácora Asambleistas:
CREATE TABLE bitacora_asambleistas (
    id_bitacora_asambleista INT AUTO_INCREMENT PRIMARY KEY,
    id_asambleista INT NOT NULL,
    cedula_anterior VARCHAR(20),
    nombre_anterior VARCHAR(150),
    razon_cambio VARCHAR(255),
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_asambleista) REFERENCES asambleista(id_asambleista)
);
