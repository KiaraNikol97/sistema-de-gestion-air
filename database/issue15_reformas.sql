-- :::::::::::::::::::::::::::::::::::::::::::::::::::
-- ISSUE #15 - Gestión de Reformas y Versionamiento
-- Autora: María Fernanda Vargas Guzmán
-- Sprint 2 - Semana 2
-- Depende de: issue10_normativo.sql, tabla catalogo_tipo_reforma, 
-- y del issue 01_issue00_base.sql
-- :::::::::::::::::::::::::::::::::::::::::::::::::::

-- .............................................
-- 1. Tabla para Registrar Reformas Aplicadas
-- .............................................

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


-- ............................................................................
-- 2. Trigger de Versionamiento Automático (versiones anteriores en histórico)
-- ............................................................................


-- Restricción real para evitar dos vigentes
ALTER TABLE elemento_normativo
ADD COLUMN id_elemento_padre_normalizado INT
GENERATED ALWAYS AS (COALESCE(id_elemento_padre, 0)) STORED;

ALTER TABLE elemento_normativo
ADD COLUMN vigente_unico INT
GENERATED ALWAYS AS (
  CASE 
    WHEN id_estado_vigencia = 1 AND fecha_fin_vigencia IS NULL THEN 1
    ELSE NULL
  END
) STORED;

CREATE UNIQUE INDEX uq_elemento_vigente
ON elemento_normativo (
  id_reglamento,
  id_elemento_padre_normalizado,
  numero_etiqueta,
  vigente_unico
);


-- Trigger 
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
END//

DELIMITER ;


-- ....................................
-- 3. Validación de Versiones Activas
-- ....................................

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
END//

DELIMITER ;


-- ...............
-- 4. Consultas 
-- ...............

-- Insertar primer versión vigente de un artículo
INSERT INTO elemento_normativo
  (id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta,
  contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
VALUES 
  (1, 2, 3, '2',
  'Texto original del artículo 2.',
  2, '2024-01-01', 1, 1);

-- Registrar reforma sobre el artículo anterior
INSERT INTO reforma_aplicada (
  id_resolucion,
  id_elemento_normativo,
  texto_anterior,
  texto_nuevo,
  fecha_inicio_vigencia,
  id_tipo_reforma,
  id_usuario_registro
)
VALUES (
  NULL,
  4,
  'Texto original del artículo 2.',
  'Texto reformado del artículo 2.',
  '2025-01-01',
  1,
  1
);

-- Verificar que solo quede una versión vigente
SELECT 
  id_elemento,
  numero_etiqueta,
  contenido_texto,
  fecha_inicio_vigencia,
  fecha_fin_vigencia,
  id_estado_vigencia
FROM elemento_normativo
WHERE id_reglamento = 1
  AND numero_etiqueta = '2'
ORDER BY fecha_inicio_vigencia;

-- .... Fin del issue #15 .....
