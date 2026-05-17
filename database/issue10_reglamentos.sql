-- ===========================================================
-- ISSUE #10 - Jerarquía de Reglamentos (Estructura Recursiva)
-- Sprint 2 - Semana 2
-- ===========================================================

-- =====================================================
-- 1. CATÁLOGOS BASE
-- =====================================================

-- Catálogo de niveles de reglamento
CREATE TABLE IF NOT EXISTS catalogo_nivel_reglamento (
    id_nivel_reglamento INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    orden INT NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);

-- Catálogo de estado de vigencia
CREATE TABLE IF NOT EXISTS catalogo_estado_vigencia (
    id_estado_vigencia INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT
);

-- =====================================================
-- 2. TABLA DE REGLAMENTOS (RAÍZ)
-- =====================================================

CREATE TABLE IF NOT EXISTS reglamento (
    id_reglamento INT PRIMARY KEY AUTO_INCREMENT,
    nombre_normativa VARCHAR(200) NOT NULL,
    sigla VARCHAR(20) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 3. DATOS INICIALES 
-- =====================================================

-- Estado de vigencia
INSERT INTO catalogo_estado_vigencia (nombre, descripcion) VALUES 
    ('Vigente', 'Activo actualmente'),
    ('Histórico', 'Versión anterior ya no vigente'),
    ('Derogado', 'Eliminado por reforma posterior')
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);

-- Niveles de reglamento
INSERT INTO catalogo_nivel_reglamento (nombre, orden) VALUES 
    ('Título', 1),
    ('Capítulo', 2),
    ('Artículo', 3),
    ('Inciso', 4),
    ('Sub-inciso', 5)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);

-- Reglamentos base
INSERT INTO reglamento (nombre_normativa, sigla) VALUES 
    ('Estatuto Orgánico del TEC', 'EO'),
    ('Reglamento de Enseñanza-Aprendizaje', 'REA'),
    ('Reglamento de Carrera Profesional', 'RCP')
ON DUPLICATE KEY UPDATE nombre_normativa = VALUES(nombre_normativa);

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ISSUE #10 - Parte 2: Tabla Recursiva elemento_normativo
-- Caro
-- Sprint 2 - Semana 2
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- 1. TABLA RECURSIVA DE ELEMENTOS NORMATIVOS
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CREATE TABLE IF NOT EXISTS elemento_normativo (
    id_elemento INT PRIMARY KEY AUTO_INCREMENT,
    id_reglamento INT NOT NULL COMMENT 'Reglamento al que pertenece',
    id_elemento_padre INT NULL COMMENT 'NULL = es raíz (Título o Capítulo principal)',
    id_nivel_reglamento INT NOT NULL COMMENT 'Título, Capítulo, Artículo, Inciso, Sub-inciso',
    numero_etiqueta VARCHAR(20) NOT NULL COMMENT 'Ej: "1", "2", "3.1", "a)", "i)"',
    contenido_texto TEXT NOT NULL COMMENT 'Texto completo del elemento',
    orden INT NOT NULL COMMENT 'Orden dentro del mismo padre (1, 2, 3...)',
    fecha_inicio_vigencia DATE NOT NULL COMMENT 'Desde cuándo está vigente',
    fecha_fin_vigencia DATE NULL COMMENT 'NULL = vigente actualmente',
    id_estado_vigencia INT NOT NULL COMMENT 'Vigente, Histórico, Derogado',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario_registro INT NOT NULL COMMENT 'Usuario que creó/ modificó',
    
    -- ÍNDICES 
    INDEX idx_elemento_reglamento (id_reglamento),
    INDEX idx_elemento_padre (id_elemento_padre),
    INDEX idx_elemento_vigencia (fecha_inicio_vigencia, fecha_fin_vigencia),
    INDEX idx_elemento_orden (id_reglamento, orden),
    INDEX idx_elemento_etiqueta (numero_etiqueta),
    INDEX idx_elemento_estado (id_estado_vigencia),
    
    -- LLAVES FORÁNEAS
    CONSTRAINT fk_elemento_reglamento 
        FOREIGN KEY (id_reglamento) REFERENCES reglamento(id_reglamento) 
        ON DELETE RESTRICT,  -- No se puede borrar un reglamento si tiene elementos
        
    CONSTRAINT fk_elemento_padre 
        FOREIGN KEY (id_elemento_padre) REFERENCES elemento_normativo(id_elemento) 
        ON DELETE RESTRICT,  -- No se puede borrar un padre si tiene hijos
        
    CONSTRAINT fk_elemento_nivel 
        FOREIGN KEY (id_nivel_reglamento) REFERENCES catalogo_nivel_reglamento(id_nivel_reglamento),
        
    CONSTRAINT fk_elemento_estado_vigencia 
        FOREIGN KEY (id_estado_vigencia) REFERENCES catalogo_estado_vigencia(id_estado_vigencia),
        
    CONSTRAINT fk_elemento_usuario 
        FOREIGN KEY (id_usuario_registro) REFERENCES sys_usuario(id_usuario),
    
    -- VALIDACIONES ADICIONALES
    CONSTRAINT chk_fechas_vigencia 
        CHECK (fecha_inicio_vigencia <= COALESCE(fecha_fin_vigencia, CURDATE())),
        
    CONSTRAINT chk_orden_positivo 
        CHECK (orden > 0)
);

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2. ÍNDICE ÚNICO PARCIAL (Regla de Oro)


-- Este índice solo aplica a registros con estado = 'Vigente'

CREATE UNIQUE INDEX idx_unique_vigente 
ON elemento_normativo (id_reglamento, numero_etiqueta, COALESCE(id_elemento_padre, 0))
WHERE id_estado_vigencia = 1;


-- 3. FUNCIÓN PARA OBTENER EL ÁRBOL COMPLETO (Recursividad)


DELIMITER //

CREATE OR REPLACE FUNCTION obtener_arbol_reglamento(p_id_reglamento INT)
RETURNS JSON
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE resultado JSON;
    
    WITH RECURSIVE arbol_cte AS (
        -- Nivel raíz (elementos sin padre)
        SELECT 
            e.id_elemento,
            e.numero_etiqueta,
            e.contenido_texto,
            e.orden,
            e.id_nivel_reglamento,
            n.nombre AS nivel_nombre,
            1 AS profundidad,
            CAST(e.orden AS CHAR(100)) AS ruta_orden
        FROM elemento_normativo e
        JOIN catalogo_nivel_reglamento n ON e.id_nivel_reglamento = n.id_nivel_reglamento
        WHERE e.id_reglamento = p_id_reglamento
          AND e.id_elemento_padre IS NULL
          AND e.fecha_fin_vigencia IS NULL
        
        UNION ALL
        
        -- Niveles hijos (recursividad)
        SELECT 
            e.id_elemento,
            e.numero_etiqueta,
            e.contenido_texto,
            e.orden,
            e.id_nivel_reglamento,
            n.nombre,
            a.profundidad + 1,
            CONCAT(a.ruta_orden, '.', e.orden)
        FROM elemento_normativo e
        JOIN catalogo_nivel_reglamento n ON e.id_nivel_reglamento = n.id_nivel_reglamento
        INNER JOIN arbol_cte a ON e.id_elemento_padre = a.id_elemento
        WHERE e.fecha_fin_vigencia IS NULL
    )
    SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
            'id', id_elemento,
            'etiqueta', numero_etiqueta,
            'contenido', contenido_texto,
            'nivel', nivel_nombre,
            'profundidad', profundidad,
            'orden', orden,
            'ruta', ruta_orden
        )
    ) INTO resultado
    FROM arbol_cte
    ORDER BY ruta_orden;
    
    RETURN COALESCE(resultado, JSON_ARRAY());
END//

DELIMITER ;

-- 4. FUNCIÓN PARA OBTENER RUTA COMPLETA DE UN ELEMENTO

DELIMITER //

CREATE OR REPLACE FUNCTION obtener_ruta_elemento(p_id_elemento INT)
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
            r.nivel + 1
        FROM elemento_normativo e
        INNER JOIN ruta_cte r ON e.id_elemento = r.id_elemento_padre
    )
    SELECT GROUP_CONCAT(numero_etiqueta ORDER BY nivel DESC SEPARATOR ' > ')
    INTO ruta
    FROM ruta_cte;
    
    RETURN COALESCE(ruta, '');
END//

DELIMITER ;


-- 5. FUNCIÓN PARA VERIFICAR SI UN ELEMENTO TIENE HIJOS

DELIMITER //

CREATE OR REPLACE FUNCTION tiene_hijos(p_id_elemento INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE cantidad INT;
    
    SELECT COUNT(*) INTO cantidad
    FROM elemento_normativo
    WHERE id_elemento_padre = p_id_elemento
      AND fecha_fin_vigencia IS NULL;
    
    RETURN cantidad > 0;
END//

DELIMITER ;


-- 6. DATOS DE EJEMPLO (Para pruebas iniciales)


--  Título de ejemplo
INSERT INTO elemento_normativo 
    (id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta, 
     contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
VALUES 
    (1, NULL, 1, 'I', 
     'Disposiciones Preliminares', 
     1, '2020-01-01', 1, 1);

-- Insertar un Capítulo dentro del Título
INSERT INTO elemento_normativo 
    (id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta, 
     contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
VALUES 
    (1, 1, 2, '1', 
     'De la Naturaleza Jurídica', 
     1, '2020-01-01', 1, 1);

-- Insertar un Artículo dentro del Capítulo
INSERT INTO elemento_normativo 
    (id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta, 
     contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
VALUES 
    (1, 2, 3, '1', 
     'El Tecnológico de Costa Rica es una institución autónoma de educación superior universitaria.', 
     1, '2020-01-01', 1, 1);


-- FIN - ISSUE #10 Parte 2

