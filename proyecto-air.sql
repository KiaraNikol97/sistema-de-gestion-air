-- =====================================================
-- SISTEMA DE GESTIÓN AIR
-- Sprint 2 y 3

-- Motor: Supabase / PostgreSQL
-- Issues integrados: 0, 9, 10, 14, 15
-- 7, 5, 11, 12, 13, 6, 16, 17
-- =====================================================

-- =====================================================
-- 0. LIMPIEZA PARA EJECUTAR EN ENTORNO LIMPIO
-- =====================================================

DROP VIEW IF EXISTS v_historial_nombramientos CASCADE;

DROP TABLE IF EXISTS reforma_aplicada CASCADE;
DROP TABLE IF EXISTS nombramiento CASCADE;
DROP TABLE IF EXISTS elemento_normativo CASCADE;
DROP TABLE IF EXISTS reglamento CASCADE;
DROP TABLE IF EXISTS sys_log_auditoria CASCADE;
DROP TABLE IF EXISTS sys_rol_permiso CASCADE;
DROP TABLE IF EXISTS sys_usuario_rol CASCADE;
DROP TABLE IF EXISTS sys_permiso CASCADE;
DROP TABLE IF EXISTS sys_rol CASCADE;
DROP TABLE IF EXISTS sys_usuario CASCADE;
DROP TABLE IF EXISTS bitacora_asambleistas CASCADE;
DROP TABLE IF EXISTS asambleista CASCADE;
DROP TABLE IF EXISTS catalogo_tipo_reforma CASCADE;
DROP TABLE IF EXISTS catalogo_estado_vigencia CASCADE;
DROP TABLE IF EXISTS catalogo_nivel_reglamento CASCADE;
DROP TABLE IF EXISTS catalogo_puestos CASCADE;
DROP TABLE IF EXISTS catalogo_sector CASCADE;

DROP FUNCTION IF EXISTS fn_auditoria_general() CASCADE;
DROP FUNCTION IF EXISTS fn_versionar_elemento_normativo() CASCADE;
DROP FUNCTION IF EXISTS fn_validar_traslape_nombramiento() CASCADE;
DROP FUNCTION IF EXISTS fn_bitacora_asambleista() CASCADE;

DROP VIEW IF EXISTS v_estado_quorum_sesion CASCADE;
DROP VIEW IF EXISTS v_informes_comision_certificacion CASCADE;
DROP VIEW IF EXISTS v_asistencia_comision CASCADE;
DROP VIEW IF EXISTS v_integrantes_comision CASCADE;
DROP VIEW IF EXISTS v_proponentes_propuesta CASCADE;

DROP TABLE IF EXISTS votacion CASCADE;
DROP TABLE IF EXISTS asistencia_sesion_plenaria CASCADE;
DROP TABLE IF EXISTS acta CASCADE;
DROP TABLE IF EXISTS sesion CASCADE;
DROP TABLE IF EXISTS resolucion CASCADE;

DROP TABLE IF EXISTS asistencia_sesion_comision CASCADE;
DROP TABLE IF EXISTS justificaciones_por_informe CASCADE;
DROP TABLE IF EXISTS justificacion_legal CASCADE;
DROP TABLE IF EXISTS informe_directorio CASCADE;
DROP TABLE IF EXISTS punto_agenda_sesion_comision CASCADE;
DROP TABLE IF EXISTS sesion_comision CASCADE;
DROP TABLE IF EXISTS bitacora_integrante_comision CASCADE;
DROP TABLE IF EXISTS integrante_comision CASCADE;
DROP TABLE IF EXISTS proposito_comision CASCADE;
DROP TABLE IF EXISTS comision CASCADE;
DROP TABLE IF EXISTS proponente_propuesta CASCADE;
DROP TABLE IF EXISTS propuesta CASCADE;

DROP TABLE IF EXISTS catalogo_tipo_sesion CASCADE;
DROP TABLE IF EXISTS catalogo_tipo_modalidad CASCADE;
DROP TABLE IF EXISTS catalogo_estado_asistencia CASCADE;
DROP TABLE IF EXISTS catalogo_tipo_tramite CASCADE;
DROP TABLE IF EXISTS catalogo_rol_comision CASCADE;
DROP TABLE IF EXISTS catalogo_tipo_comision CASCADE;
DROP TABLE IF EXISTS catalogo_tipo_propuesta CASCADE;
DROP TABLE IF EXISTS catalogo_estado_propuesta CASCADE;

DROP VIEW IF EXISTS v_memoria_votacion_sesion CASCADE;

DROP TABLE IF EXISTS bitacora_estado_votacion CASCADE;
DROP TABLE IF EXISTS punto_agenda_sesion CASCADE;

DROP VIEW IF EXISTS v_resultado_votacion_detalle CASCADE;
DROP VIEW IF EXISTS v_votos_nominales CASCADE;

DROP TABLE IF EXISTS voto_asambleista CASCADE;
DROP TABLE IF EXISTS resultado_votacion CASCADE;
DROP TABLE IF EXISTS catalogo_tipo_voto CASCADE;
DROP TABLE IF EXISTS catalogo_tipo_votacion CASCADE;
DROP TABLE IF EXISTS catalogo_tipo_mayoria_requerida CASCADE;

DROP VIEW IF EXISTS v_auditoria_forense CASCADE;
DROP FUNCTION IF EXISTS fn_auditoria_forense() CASCADE;

DROP VIEW IF EXISTS v_compilador_normativo_vigente CASCADE;
DROP VIEW IF EXISTS v_arbol_normativo CASCADE;
DROP VIEW IF EXISTS v_leyendas_propuesta CASCADE;

DROP TABLE IF EXISTS propuesta_leyenda CASCADE;
DROP TABLE IF EXISTS leyenda_nota_condicional CASCADE;
DROP TABLE IF EXISTS catalogo_origen_propuesta CASCADE;
DROP TABLE IF EXISTS catalogo_etapa_propuesta CASCADE;

DROP VIEW IF EXISTS v_compilador_historico_fecha CASCADE;
DROP VIEW IF EXISTS v_historial_vigencia_elemento CASCADE;
DROP VIEW IF EXISTS v_trazabilidad_normativa CASCADE;

DROP FUNCTION IF EXISTS obtener_texto_vigente_en_fecha(INTEGER, DATE) CASCADE;
DROP FUNCTION IF EXISTS obtener_arbol_normativo_vigente(INTEGER, DATE) CASCADE;
DROP FUNCTION IF EXISTS obtener_historial_elemento(INTEGER) CASCADE;

DROP VIEW IF EXISTS v_verificacion_certificacion CASCADE;
DROP VIEW IF EXISTS v_certificacion_datos_consolidados CASCADE;
DROP VIEW IF EXISTS v_reporte_certificaciones_mensual CASCADE;

DROP TABLE IF EXISTS verificacion_externa CASCADE;
DROP TABLE IF EXISTS certificacion_detalle CASCADE;
DROP TABLE IF EXISTS anulacion_certificacion CASCADE;
DROP TABLE IF EXISTS solicitud_certificacion CASCADE;
DROP TABLE IF EXISTS certificacion_emitida CASCADE;
DROP TABLE IF EXISTS control_folio CASCADE;

DROP FUNCTION IF EXISTS fn_generar_folio_certificacion() CASCADE;
DROP FUNCTION IF EXISTS fn_generar_hash_certificacion() CASCADE;
DROP FUNCTION IF EXISTS fn_preparar_certificacion() CASCADE;
DROP FUNCTION IF EXISTS fn_anular_certificacion(INTEGER, TEXT, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS fn_registrar_verificacion_externa(VARCHAR) CASCADE;

DROP FUNCTION IF EXISTS fn_crear_verificacion_certificacion() CASCADE;

DROP FUNCTION IF EXISTS fn_no_repudio_certificacion() CASCADE;
DROP FUNCTION IF EXISTS fn_validar_voto_asambleista() CASCADE;
DROP FUNCTION IF EXISTS fn_recalcular_resultado_votacion(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS fn_trigger_recalcular_resultado_votacion() CASCADE;
DROP FUNCTION IF EXISTS fn_calcular_resultado_votacion_detalle(INTEGER, INTEGER, INTEGER, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS fn_validar_resumen_votacion() CASCADE;
DROP FUNCTION IF EXISTS fn_bitacora_estado_votacion() CASCADE;
DROP FUNCTION IF EXISTS fn_aplicar_leyendas_propuesta() CASCADE;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================================
-- 1. CATÁLOGOS COMPARTIDOS
-- =====================================================

CREATE TABLE IF NOT EXISTS catalogo_sector (
    id_sector INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS catalogo_puestos (
    id_puesto INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre_puesto VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS catalogo_nivel_reglamento (
    id_nivel_reglamento INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    orden INTEGER NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_nivel_orden_positivo CHECK (orden > 0)
);

CREATE TABLE IF NOT EXISTS catalogo_estado_vigencia (
    id_estado_vigencia INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT
);

CREATE TABLE IF NOT EXISTS catalogo_tipo_reforma (
    id_tipo_reforma INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT
);

-- Catálogos Nuevos (Sprint 3):

CREATE TABLE IF NOT EXISTS catalogo_estado_propuesta (
    id_estado_propuesta INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_estado_propuesta_no_vacio CHECK (BTRIM(nombre) <> '')
);

CREATE TABLE IF NOT EXISTS catalogo_tipo_propuesta (
    id_tipo_propuesta INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    leyenda_legal TEXT,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_tipo_propuesta_no_vacio CHECK (BTRIM(nombre) <> '')
);

CREATE TABLE IF NOT EXISTS catalogo_tipo_comision (
    id_tipo_comision INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_tipo_comision_no_vacio CHECK (BTRIM(nombre) <> '')
);

CREATE TABLE IF NOT EXISTS catalogo_rol_comision (
    id_rol_comision INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre_rol VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_rol_comision_no_vacio CHECK (BTRIM(nombre_rol) <> '')
);

CREATE TABLE IF NOT EXISTS catalogo_tipo_tramite (
    id_tipo_tramite INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_tipo_tramite_no_vacio CHECK (BTRIM(nombre) <> '')
);

CREATE TABLE IF NOT EXISTS catalogo_estado_asistencia (
    id_estado_asistencia INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_estado_asistencia_no_vacio CHECK (BTRIM(nombre) <> '')
);

CREATE TABLE IF NOT EXISTS catalogo_tipo_sesion (
    id_tipo_sesion INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    quorum_porcentaje NUMERIC(5,2) NOT NULL DEFAULT 50.00,
    requiere_mayoria_calificada BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE,

    CONSTRAINT chk_quorum_porcentaje
        CHECK (quorum_porcentaje > 0 AND quorum_porcentaje <= 100),

    CONSTRAINT chk_nombre_tipo_sesion_no_vacio
        CHECK (BTRIM(nombre) <> '')
);

CREATE TABLE IF NOT EXISTS catalogo_tipo_modalidad (
    id_tipo_modalidad INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,

    CONSTRAINT chk_nombre_modalidad_no_vacio
        CHECK (BTRIM(nombre) <> '')
);

CREATE TABLE IF NOT EXISTS catalogo_tipo_mayoria_requerida (
    id_tipo_mayoria_requerida INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    porcentaje_requerido NUMERIC(5,2) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,

    CONSTRAINT chk_porcentaje_mayoria
        CHECK (porcentaje_requerido > 0 AND porcentaje_requerido <= 100),

    CONSTRAINT chk_nombre_mayoria_no_vacio
        CHECK (BTRIM(nombre) <> '')
);

CREATE TABLE IF NOT EXISTS catalogo_tipo_votacion (
    id_tipo_votacion INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,

    CONSTRAINT chk_nombre_tipo_votacion_no_vacio
        CHECK (BTRIM(nombre) <> '')
);

CREATE TABLE IF NOT EXISTS catalogo_tipo_voto (
    id_tipo_voto INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,

    CONSTRAINT chk_nombre_tipo_voto_no_vacio
        CHECK (BTRIM(nombre) <> '')
);

CREATE TABLE IF NOT EXISTS catalogo_etapa_propuesta (
    id_etapa_propuesta INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    orden INTEGER NOT NULL DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_etapa_propuesta_no_vacia
        CHECK (BTRIM(nombre) <> ''),

    CONSTRAINT chk_orden_etapa_propuesta
        CHECK (orden >= 0)
);

CREATE TABLE IF NOT EXISTS catalogo_origen_propuesta (
    id_origen_propuesta INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    codigo VARCHAR(20) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,

    CONSTRAINT chk_origen_propuesta_no_vacio
        CHECK (BTRIM(nombre) <> ''),

    CONSTRAINT chk_codigo_origen_no_vacio
        CHECK (BTRIM(codigo) <> '')
);

-- =====================================================
-- 2. ASAMBLEÍSTAS - ISSUE #9
-- =====================================================

CREATE TABLE asambleista (
    id_asambleista INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cedula VARCHAR(11) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    correo_institucional VARCHAR(150),

    CONSTRAINT chk_cedula_formato
        CHECK (cedula ~ '^[0-9]-[0-9]{4}-[0-9]{4}$'),

    CONSTRAINT chk_nombre_no_vacio
        CHECK (BTRIM(nombre) <> ''),

    CONSTRAINT chk_correo_institucional
        CHECK (
            correo_institucional IS NULL
            OR correo_institucional = ''
            OR correo_institucional LIKE '%@%'
        )
);

CREATE TABLE bitacora_asambleistas (
    id_bitacora_asambleista INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_asambleista INTEGER NOT NULL,
    cedula_anterior VARCHAR(11),
    cedula_nueva VARCHAR(11),
    nombre_anterior VARCHAR(150),
    nombre_nuevo VARCHAR(150),
    correo_anterior VARCHAR(150),
    correo_nuevo VARCHAR(150),
    razon_cambio VARCHAR(255),
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_bitacora_asambleista
        FOREIGN KEY (id_asambleista)
        REFERENCES asambleista(id_asambleista)
        ON DELETE CASCADE
);

-- =====================================================
-- 3. SEGURIDAD Y AUDITORÍA - ISSUE #0
-- =====================================================

CREATE TABLE sys_usuario (
    id_usuario INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    id_asambleista INTEGER NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_usuario_asambleista
        FOREIGN KEY (id_asambleista)
        REFERENCES asambleista(id_asambleista)
        ON DELETE SET NULL
);

CREATE TABLE sys_rol (
    id_rol INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre_rol VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sys_permiso (
    id_permiso INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre_permiso VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT
);

CREATE TABLE sys_usuario_rol (
    id_usuario INTEGER NOT NULL,
    id_rol INTEGER NOT NULL,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id_usuario, id_rol),

    CONSTRAINT fk_usuario_rol_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE CASCADE,

    CONSTRAINT fk_usuario_rol_rol
        FOREIGN KEY (id_rol)
        REFERENCES sys_rol(id_rol)
        ON DELETE CASCADE
);

CREATE TABLE sys_rol_permiso (
    id_rol INTEGER NOT NULL,
    id_permiso INTEGER NOT NULL,

    PRIMARY KEY (id_rol, id_permiso),

    CONSTRAINT fk_rol_permiso_rol
        FOREIGN KEY (id_rol)
        REFERENCES sys_rol(id_rol)
        ON DELETE CASCADE,

    CONSTRAINT fk_rol_permiso_permiso
        FOREIGN KEY (id_permiso)
        REFERENCES sys_permiso(id_permiso)
        ON DELETE CASCADE
);

CREATE TABLE sys_log_auditoria (
    id_log INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_usuario INTEGER NULL,
    accion VARCHAR(100) NOT NULL,
    tabla_afectada VARCHAR(100),
    detalle TEXT,
    ip_origen VARCHAR(45),
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_log_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE SET NULL
);

-- =====================================================
-- 4. NORMATIVA - ISSUE #10
-- =====================================================

CREATE TABLE reglamento (
    id_reglamento INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre_normativa VARCHAR(200) NOT NULL,
    sigla VARCHAR(20) UNIQUE NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_nombre_normativa_no_vacio CHECK (BTRIM(nombre_normativa) <> ''),
    CONSTRAINT chk_sigla_no_vacia CHECK (BTRIM(sigla) <> '')
);

CREATE TABLE elemento_normativo (
    id_elemento INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_reglamento INTEGER NOT NULL,
    id_elemento_padre INTEGER NULL,
    id_nivel_reglamento INTEGER NOT NULL,
    numero_etiqueta VARCHAR(20) NOT NULL,
    contenido_texto TEXT NOT NULL,
    orden INTEGER NOT NULL,
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE NULL,
    id_estado_vigencia INTEGER NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario_registro INTEGER NOT NULL,

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

    CONSTRAINT chk_numero_etiqueta_no_vacio
        CHECK (BTRIM(numero_etiqueta) <> ''),

    CONSTRAINT chk_contenido_texto_no_vacio
        CHECK (BTRIM(contenido_texto) <> '')
);

CREATE INDEX idx_elemento_reglamento ON elemento_normativo(id_reglamento);
CREATE INDEX idx_elemento_padre ON elemento_normativo(id_elemento_padre);
CREATE INDEX idx_elemento_vigencia ON elemento_normativo(fecha_inicio_vigencia, fecha_fin_vigencia);
CREATE INDEX idx_elemento_estado ON elemento_normativo(id_estado_vigencia);

-- Evita que existan dos versiones vigentes del mismo elemento lógico.
CREATE UNIQUE INDEX uq_elemento_vigente
ON elemento_normativo (
    id_reglamento,
    COALESCE(id_elemento_padre, 0),
    numero_etiqueta
)
WHERE id_estado_vigencia = 1 AND fecha_fin_vigencia IS NULL;

-- =====================================================
-- 5. NOMBRAMIENTOS - ISSUE #14
-- =====================================================

CREATE TABLE nombramiento (
    id_nombramiento INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_asambleista INTEGER NOT NULL,
    id_sector INTEGER NOT NULL,
    id_puesto INTEGER NOT NULL,
    resolucion_id INTEGER NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NULL,
    estado VARCHAR(20) DEFAULT 'Activo',
    id_usuario_registro INTEGER NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,

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
        CHECK (fecha_fin IS NULL OR fecha_inicio <= fecha_fin),

    CONSTRAINT chk_estado_nombramiento
        CHECK (estado IN ('Activo', 'Finalizado', 'Suspendido'))
);

CREATE INDEX idx_nombramiento_asambleista ON nombramiento(id_asambleista);
CREATE INDEX idx_nombramiento_sector ON nombramiento(id_sector);
CREATE INDEX idx_nombramiento_fechas ON nombramiento(fecha_inicio, fecha_fin);
CREATE INDEX idx_nombramiento_estado ON nombramiento(estado);

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
        WHEN n.fecha_fin < CURRENT_DATE THEN 'Vencido'
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
    id_reforma INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_resolucion INTEGER NULL,
    id_elemento_normativo INTEGER NOT NULL,
    texto_anterior TEXT NOT NULL,
    texto_nuevo TEXT NOT NULL,
    fecha_inicio_vigencia DATE NOT NULL,
    id_tipo_reforma INTEGER NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario_registro INTEGER NOT NULL,

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

CREATE INDEX idx_reforma_elemento ON reforma_aplicada(id_elemento_normativo);
CREATE INDEX idx_reforma_fecha ON reforma_aplicada(fecha_inicio_vigencia);
CREATE INDEX idx_reforma_tipo ON reforma_aplicada(id_tipo_reforma);

-- =====================================================
-- 7. GESTIÓN DE COMISIONES DE ANÁLISIS - ISSUE #7
-- =====================================================

-- Propuestas
CREATE TABLE IF NOT EXISTS propuesta (
    id_propuesta INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    numero_propuesta VARCHAR(12) UNIQUE NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    id_tipo_propuesta INTEGER NOT NULL,
    id_estado_propuesta INTEGER NOT NULL,
    id_elemento_normativo INTEGER,
    fecha_presentacion DATE NOT NULL DEFAULT CURRENT_DATE,
    id_usuario_registro INTEGER,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_propuesta_tipo
        FOREIGN KEY (id_tipo_propuesta)
        REFERENCES catalogo_tipo_propuesta(id_tipo_propuesta)
        ON DELETE RESTRICT,

    CONSTRAINT fk_propuesta_estado
        FOREIGN KEY (id_estado_propuesta)
        REFERENCES catalogo_estado_propuesta(id_estado_propuesta)
        ON DELETE RESTRICT,

    CONSTRAINT fk_propuesta_elemento
        FOREIGN KEY (id_elemento_normativo)
        REFERENCES elemento_normativo(id_elemento)
        ON DELETE SET NULL,

    CONSTRAINT fk_propuesta_usuario
        FOREIGN KEY (id_usuario_registro)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE SET NULL,

    -- Formato: AIR-XXX-YYYY
    CONSTRAINT chk_numero_propuesta_formato
        CHECK (numero_propuesta ~ '^AIR-[0-9]{3}-[0-9]{4}$'),

    CONSTRAINT chk_titulo_propuesta_no_vacio
        CHECK (BTRIM(titulo) <> '')
);

CREATE TABLE IF NOT EXISTS proponente_propuesta (
    id_proponente_propuesta INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_propuesta INTEGER NOT NULL,
    id_asambleista INTEGER NOT NULL,
    rol_proponente VARCHAR(50) DEFAULT 'Proponente',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_proponente_propuesta
        FOREIGN KEY (id_propuesta)
        REFERENCES propuesta(id_propuesta)
        ON DELETE CASCADE,

    CONSTRAINT fk_proponente_asambleista
        FOREIGN KEY (id_asambleista)
        REFERENCES asambleista(id_asambleista)
        ON DELETE RESTRICT,

    CONSTRAINT uq_proponente_propuesta
        UNIQUE (id_propuesta, id_asambleista)
);

-- Comisiones
CREATE TABLE IF NOT EXISTS comision (
    id_comision INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_tipo_comision INTEGER NOT NULL,
    nombre_comision VARCHAR(150) NOT NULL,
    objeto TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,

    CONSTRAINT fk_comision_tipo
        FOREIGN KEY (id_tipo_comision)
        REFERENCES catalogo_tipo_comision(id_tipo_comision)
        ON DELETE RESTRICT,

    CONSTRAINT chk_nombre_comision_no_vacio
        CHECK (BTRIM(nombre_comision) <> '')
);

CREATE TABLE IF NOT EXISTS proposito_comision (
    id_proposito_comision INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_comision INTEGER NOT NULL,
    id_propuesta INTEGER NOT NULL,
    texto TEXT NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_proposito_comision
        FOREIGN KEY (id_comision)
        REFERENCES comision(id_comision)
        ON DELETE CASCADE,

    CONSTRAINT fk_proposito_propuesta
        FOREIGN KEY (id_propuesta)
        REFERENCES propuesta(id_propuesta)
        ON DELETE RESTRICT,

    CONSTRAINT chk_texto_proposito_no_vacio
        CHECK (BTRIM(texto) <> '')
);

-- Integrantes de Comisión
CREATE TABLE IF NOT EXISTS integrante_comision (
    id_integrante_comision INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_comision INTEGER NOT NULL,
    id_asambleista INTEGER NOT NULL,
    id_rol_comision INTEGER NOT NULL,
    fecha_ingreso_nombramiento DATE NOT NULL,
    fecha_fin_nombramiento DATE,
    estado VARCHAR(20) NOT NULL DEFAULT 'Activo',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_integrante_comision
        FOREIGN KEY (id_comision)
        REFERENCES comision(id_comision)
        ON DELETE CASCADE,

    CONSTRAINT fk_integrante_asambleista
        FOREIGN KEY (id_asambleista)
        REFERENCES asambleista(id_asambleista)
        ON DELETE RESTRICT,

    CONSTRAINT fk_integrante_rol
        FOREIGN KEY (id_rol_comision)
        REFERENCES catalogo_rol_comision(id_rol_comision)
        ON DELETE RESTRICT,

    CONSTRAINT chk_estado_integrante
        CHECK (estado IN ('Activo', 'Inactivo')),

    CONSTRAINT chk_fechas_integrante
        CHECK (
            fecha_fin_nombramiento IS NULL
            OR fecha_fin_nombramiento >= fecha_ingreso_nombramiento
        )
);

CREATE TABLE IF NOT EXISTS bitacora_integrante_comision (
    id_bitacora_integrante_comision INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_integrante_comision INTEGER NOT NULL,
    id_comision INTEGER NOT NULL,
    id_asambleista INTEGER NOT NULL,
    id_rol_comision INTEGER NOT NULL,
    fecha_ingreso_nombramiento DATE NOT NULL,
    fecha_fin_nombramiento DATE,
    estado VARCHAR(20) NOT NULL,
    accion VARCHAR(20) NOT NULL,
    fecha_bitacora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_bitacora_integrante
        FOREIGN KEY (id_integrante_comision)
        REFERENCES integrante_comision(id_integrante_comision)
        ON DELETE CASCADE
);

-- Sesiones de Comisión y Agenda
CREATE TABLE IF NOT EXISTS sesion_comision (
    id_sesion_comision INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_comision INTEGER NOT NULL,
    fecha_hora TIMESTAMP NOT NULL,
    observaciones TEXT,

    CONSTRAINT fk_sesion_comision
        FOREIGN KEY (id_comision)
        REFERENCES comision(id_comision)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS punto_agenda_sesion_comision (
    id_punto_agenda_sesion_comision INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_sesion_comision INTEGER NOT NULL,
    id_proposito_comision INTEGER NOT NULL,
    id_tipo_tramite INTEGER NOT NULL,
    orden INTEGER NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,

    CONSTRAINT fk_punto_sesion_comision
        FOREIGN KEY (id_sesion_comision)
        REFERENCES sesion_comision(id_sesion_comision)
        ON DELETE CASCADE,

    CONSTRAINT fk_punto_proposito
        FOREIGN KEY (id_proposito_comision)
        REFERENCES proposito_comision(id_proposito_comision)
        ON DELETE RESTRICT,

    CONSTRAINT fk_punto_tipo_tramite
        FOREIGN KEY (id_tipo_tramite)
        REFERENCES catalogo_tipo_tramite(id_tipo_tramite)
        ON DELETE RESTRICT,

    CONSTRAINT uq_orden_sesion_comision
        UNIQUE (id_sesion_comision, orden),

    CONSTRAINT chk_orden_punto_comision
        CHECK (orden > 0),

    CONSTRAINT chk_titulo_punto_no_vacio
        CHECK (BTRIM(titulo) <> '')
);

-- Informes del Directorio y Justificación Legal
CREATE TABLE IF NOT EXISTS informe_directorio (
    id_informe INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_comision INTEGER NOT NULL,
    id_propuesta INTEGER NOT NULL,
    id_sesion_comision INTEGER,
    titulo VARCHAR(200) NOT NULL,
    recomendacion TEXT,
    fecha_presentacion DATE,

    CONSTRAINT fk_informe_comision
        FOREIGN KEY (id_comision)
        REFERENCES comision(id_comision)
        ON DELETE RESTRICT,

    CONSTRAINT fk_informe_propuesta
        FOREIGN KEY (id_propuesta)
        REFERENCES propuesta(id_propuesta)
        ON DELETE RESTRICT,

    CONSTRAINT fk_informe_sesion_comision
        FOREIGN KEY (id_sesion_comision)
        REFERENCES sesion_comision(id_sesion_comision)
        ON DELETE SET NULL,

    CONSTRAINT chk_titulo_informe_no_vacio
        CHECK (BTRIM(titulo) <> '')
);

CREATE TABLE IF NOT EXISTS justificacion_legal (
    id_argumento INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    es_considerando BOOLEAN NOT NULL,
    contenido TEXT NOT NULL,

    CONSTRAINT chk_contenido_argumento_no_vacio
        CHECK (BTRIM(contenido) <> '')
);

CREATE TABLE IF NOT EXISTS justificaciones_por_informe (
    id_informe INTEGER NOT NULL,
    id_argumento INTEGER NOT NULL,
    orden_aparicion INTEGER NOT NULL,

    PRIMARY KEY (id_informe, id_argumento),

    CONSTRAINT fk_justificacion_informe
        FOREIGN KEY (id_informe)
        REFERENCES informe_directorio(id_informe)
        ON DELETE CASCADE,

    CONSTRAINT fk_justificacion_argumento
        FOREIGN KEY (id_argumento)
        REFERENCES justificacion_legal(id_argumento)
        ON DELETE RESTRICT,

    CONSTRAINT chk_orden_justificacion
        CHECK (orden_aparicion > 0),

    CONSTRAINT uq_orden_justificacion_informe
        UNIQUE (id_informe, orden_aparicion)
);

-- Asistencia a Sesiones de Comisión
CREATE TABLE IF NOT EXISTS asistencia_sesion_comision (
    id_asistencia_comision INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_asambleista INTEGER NOT NULL,
    id_sesion_comision INTEGER NOT NULL,
    id_comision INTEGER NOT NULL,
    id_estado_asistencia INTEGER NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_asistencia_comision_asambleista
        FOREIGN KEY (id_asambleista)
        REFERENCES asambleista(id_asambleista)
        ON DELETE RESTRICT,

    CONSTRAINT fk_asistencia_sesion_comision
        FOREIGN KEY (id_sesion_comision)
        REFERENCES sesion_comision(id_sesion_comision)
        ON DELETE CASCADE,

    CONSTRAINT fk_asistencia_comision
        FOREIGN KEY (id_comision)
        REFERENCES comision(id_comision)
        ON DELETE CASCADE,

    CONSTRAINT fk_asistencia_estado
        FOREIGN KEY (id_estado_asistencia)
        REFERENCES catalogo_estado_asistencia(id_estado_asistencia)
        ON DELETE RESTRICT,

    CONSTRAINT uq_asistencia_comision
        UNIQUE (id_asambleista, id_sesion_comision)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_propuesta_numero ON propuesta(numero_propuesta);
CREATE INDEX IF NOT EXISTS idx_propuesta_estado ON propuesta(id_estado_propuesta);
CREATE INDEX IF NOT EXISTS idx_propuesta_tipo ON propuesta(id_tipo_propuesta);
CREATE INDEX IF NOT EXISTS idx_proponente_propuesta ON proponente_propuesta(id_propuesta);
CREATE INDEX IF NOT EXISTS idx_proponente_asambleista ON proponente_propuesta(id_asambleista);

CREATE INDEX IF NOT EXISTS idx_proposito_comision ON proposito_comision(id_comision);
CREATE INDEX IF NOT EXISTS idx_proposito_propuesta ON proposito_comision(id_propuesta);

CREATE INDEX IF NOT EXISTS idx_integrante_comision ON integrante_comision(id_comision);
CREATE INDEX IF NOT EXISTS idx_integrante_asambleista ON integrante_comision(id_asambleista);
CREATE INDEX IF NOT EXISTS idx_integrante_fechas ON integrante_comision(fecha_ingreso_nombramiento, fecha_fin_nombramiento);

CREATE INDEX IF NOT EXISTS idx_sesion_comision ON sesion_comision(id_comision);
CREATE INDEX IF NOT EXISTS idx_sesion_comision_fecha ON sesion_comision(fecha_hora);

CREATE INDEX IF NOT EXISTS idx_informe_comision ON informe_directorio(id_comision);
CREATE INDEX IF NOT EXISTS idx_informe_propuesta ON informe_directorio(id_propuesta);

CREATE INDEX IF NOT EXISTS idx_asistencia_comision_sesion ON asistencia_sesion_comision(id_sesion_comision);
CREATE INDEX IF NOT EXISTS idx_asistencia_comision_asambleista ON asistencia_sesion_comision(id_asambleista);

-- ==========================================================
-- 8. REGISTRO DE SESIONES Y MEMORIA DE VOTACIÓN - ISSUE #5
-- ==========================================================

-- Sesiones
CREATE TABLE IF NOT EXISTS sesion (
    id_sesion INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_tipo_modalidad INTEGER NOT NULL,
    id_tipo_sesion INTEGER NOT NULL,
    numero_sesion VARCHAR(50) UNIQUE NOT NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME,
    hora_fin TIME,
    link_acta VARCHAR(500),
    quorum_requerido INTEGER,
    total_asambleistas INTEGER,
    estado VARCHAR(30) DEFAULT 'Programada',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario_registro INTEGER,

    CONSTRAINT fk_sesion_modalidad
        FOREIGN KEY (id_tipo_modalidad)
        REFERENCES catalogo_tipo_modalidad(id_tipo_modalidad)
        ON DELETE RESTRICT,

    CONSTRAINT fk_sesion_tipo
        FOREIGN KEY (id_tipo_sesion)
        REFERENCES catalogo_tipo_sesion(id_tipo_sesion)
        ON DELETE RESTRICT,

    CONSTRAINT fk_sesion_usuario
        FOREIGN KEY (id_usuario_registro)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE SET NULL,

    CONSTRAINT chk_estado_sesion
        CHECK (estado IN ('Programada', 'En Curso', 'Finalizada', 'Cancelada')),

    CONSTRAINT chk_numero_sesion_no_vacio
        CHECK (BTRIM(numero_sesion) <> ''),

    CONSTRAINT chk_horas_sesion
        CHECK (hora_fin IS NULL OR hora_inicio IS NULL OR hora_fin >= hora_inicio),

    CONSTRAINT chk_totales_sesion
        CHECK (total_asambleistas IS NULL OR total_asambleistas >= 0),

    CONSTRAINT chk_quorum_requerido_sesion
        CHECK (quorum_requerido IS NULL OR quorum_requerido >= 0)
);

-- Actas
CREATE TABLE IF NOT EXISTS acta (
    id_acta INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_sesion INTEGER NOT NULL,
    numero_acta VARCHAR(50) UNIQUE NOT NULL,
    fecha_aprobacion DATE,
    url_documento VARCHAR(500),
    contenido_resumen TEXT,
    observaciones TEXT,
    estado VARCHAR(30) DEFAULT 'Borrador',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario_registro INTEGER,

    CONSTRAINT fk_acta_sesion
        FOREIGN KEY (id_sesion)
        REFERENCES sesion(id_sesion)
        ON DELETE CASCADE,

    CONSTRAINT fk_acta_usuario
        FOREIGN KEY (id_usuario_registro)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE SET NULL,

    CONSTRAINT chk_estado_acta
        CHECK (estado IN ('Borrador', 'En Revision', 'Aprobada', 'Publicada')),

    CONSTRAINT chk_numero_acta_no_vacio
        CHECK (BTRIM(numero_acta) <> '')
);

CREATE TABLE IF NOT EXISTS punto_agenda_sesion (
    id_punto_agenda_sesion INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_sesion INTEGER NOT NULL,
    id_propuesta INTEGER,
    orden INTEGER NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,

    CONSTRAINT fk_punto_agenda_sesion
        FOREIGN KEY (id_sesion)
        REFERENCES sesion(id_sesion)
        ON DELETE CASCADE,

    CONSTRAINT fk_punto_agenda_propuesta
        FOREIGN KEY (id_propuesta)
        REFERENCES propuesta(id_propuesta)
        ON DELETE SET NULL,

    CONSTRAINT uq_orden_agenda_sesion
        UNIQUE (id_sesion, orden),

    CONSTRAINT chk_orden_agenda_sesion
        CHECK (orden > 0),

    CONSTRAINT chk_titulo_agenda_no_vacio
        CHECK (BTRIM(titulo) <> '')
);

-- Resolución
CREATE TABLE IF NOT EXISTS resolucion (
    id_resolucion INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_sesion INTEGER NOT NULL,
    id_punto_agenda_sesion INTEGER,
    numero_resolucion VARCHAR(50) NOT NULL,
    fecha_emision DATE NOT NULL DEFAULT CURRENT_DATE,
    descripcion TEXT,
    id_usuario_registro INTEGER,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_resolucion_sesion
        FOREIGN KEY (id_sesion)
        REFERENCES sesion(id_sesion)
        ON DELETE RESTRICT,

    CONSTRAINT fk_resolucion_punto_agenda
        FOREIGN KEY (id_punto_agenda_sesion)
        REFERENCES punto_agenda_sesion(id_punto_agenda_sesion)
        ON DELETE SET NULL,

    CONSTRAINT fk_resolucion_usuario
        FOREIGN KEY (id_usuario_registro)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE SET NULL,

    CONSTRAINT chk_numero_resolucion_no_vacio
        CHECK (BTRIM(numero_resolucion) <> ''),

    CONSTRAINT chk_formato_resolucion
        CHECK (numero_resolucion ~ '^AIR-RES-[0-9]{3}-[0-9]{4}$')
);

CREATE INDEX IF NOT EXISTS idx_resolucion_sesion
    ON resolucion(id_sesion);

CREATE INDEX IF NOT EXISTS idx_resolucion_numero
    ON resolucion(numero_resolucion);

-- Votación
CREATE TABLE IF NOT EXISTS votacion (
    id_votacion INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_sesion INTEGER NOT NULL,
    id_propuesta INTEGER,
    id_elemento_normativo INTEGER,
    numero_votacion VARCHAR(50),
    tipo_votacion VARCHAR(30) DEFAULT 'Publica',
    votos_favor INTEGER DEFAULT 0,
    votos_contra INTEGER DEFAULT 0,
    votos_abstencion INTEGER DEFAULT 0,
    total_votantes INTEGER DEFAULT 0,
    resultado VARCHAR(30) DEFAULT 'Pendiente',
    estado_acuerdo VARCHAR(30) DEFAULT 'Borrador',
    fecha_firma_acuerdo TIMESTAMP,
    id_usuario_firma INTEGER,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_votacion_sesion
        FOREIGN KEY (id_sesion)
        REFERENCES sesion(id_sesion)
        ON DELETE CASCADE,

    CONSTRAINT fk_votacion_propuesta
        FOREIGN KEY (id_propuesta)
        REFERENCES propuesta(id_propuesta)
        ON DELETE SET NULL,

    CONSTRAINT fk_votacion_elemento_normativo
        FOREIGN KEY (id_elemento_normativo)
        REFERENCES elemento_normativo(id_elemento)
        ON DELETE SET NULL,

    CONSTRAINT fk_votacion_usuario_firma
        FOREIGN KEY (id_usuario_firma)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE SET NULL,

    CONSTRAINT chk_tipo_votacion
        CHECK (tipo_votacion IN ('Publica', 'Secreta')),

    CONSTRAINT chk_resultado_votacion
        CHECK (resultado IN ('Aprobada', 'Rechazada', 'Empate', 'Pendiente')),

    CONSTRAINT chk_estado_acuerdo
        CHECK (estado_acuerdo IN ('Borrador', 'Firmado', 'Anulado')),

    CONSTRAINT chk_votos_no_negativos
        CHECK (
            votos_favor >= 0
            AND votos_contra >= 0
            AND votos_abstencion >= 0
            AND total_votantes >= 0
        )
);

CREATE TABLE IF NOT EXISTS bitacora_estado_votacion (
    id_bitacora_estado_votacion INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_votacion INTEGER NOT NULL,
    estado_anterior VARCHAR(30),
    estado_nuevo VARCHAR(30) NOT NULL,
    id_usuario INTEGER,
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,

    CONSTRAINT fk_bitacora_votacion
        FOREIGN KEY (id_votacion)
        REFERENCES votacion(id_votacion)
        ON DELETE CASCADE,

    CONSTRAINT fk_bitacora_votacion_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE SET NULL
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_sesion_fecha ON sesion(fecha);
CREATE INDEX IF NOT EXISTS idx_sesion_estado ON sesion(estado);
CREATE INDEX IF NOT EXISTS idx_acta_sesion ON acta(id_sesion);
CREATE INDEX IF NOT EXISTS idx_votacion_sesion ON votacion(id_sesion);
CREATE INDEX IF NOT EXISTS idx_punto_agenda_sesion ON punto_agenda_sesion(id_sesion);
CREATE INDEX IF NOT EXISTS idx_punto_agenda_propuesta ON punto_agenda_sesion(id_propuesta);
CREATE INDEX IF NOT EXISTS idx_votacion_propuesta ON votacion(id_propuesta);
CREATE INDEX IF NOT EXISTS idx_votacion_estado_acuerdo ON votacion(estado_acuerdo);

-- =====================================================
-- 9. CONTROL DE QUÓRUM Y SESIONES - ISSUE #11
-- =====================================================

-- Asistencia de Sesiones Plenarias
CREATE TABLE IF NOT EXISTS asistencia_sesion_plenaria (
    id_asistencia INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_asambleista INTEGER NOT NULL,
    id_sesion INTEGER NOT NULL,
    id_estado_asistencia INTEGER NOT NULL,
    hora_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,

    CONSTRAINT fk_asistencia_asambleista
        FOREIGN KEY (id_asambleista)
        REFERENCES asambleista(id_asambleista)
        ON DELETE CASCADE,

    CONSTRAINT fk_asistencia_sesion
        FOREIGN KEY (id_sesion)
        REFERENCES sesion(id_sesion)
        ON DELETE CASCADE,

    CONSTRAINT fk_asistencia_estado
        FOREIGN KEY (id_estado_asistencia)
        REFERENCES catalogo_estado_asistencia(id_estado_asistencia)
        ON DELETE RESTRICT,

    CONSTRAINT uq_asistencia_sesion
        UNIQUE (id_asambleista, id_sesion)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_asistencia_sesion ON asistencia_sesion_plenaria(id_sesion);
CREATE INDEX IF NOT EXISTS idx_asistencia_asambleista ON asistencia_sesion_plenaria(id_asambleista);

-- =====================================================
-- 10. MOTOR DE VOTACIONES - ISSUE #12
-- =====================================================

CREATE TABLE IF NOT EXISTS resultado_votacion (
    id_resultado_votacion INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_votacion INTEGER NOT NULL UNIQUE,
    id_tipo_mayoria_requerida INTEGER NOT NULL,
    id_tipo_votacion INTEGER NOT NULL,
    total_presentes INTEGER NOT NULL DEFAULT 0,
    total_votos INTEGER NOT NULL DEFAULT 0,
    votos_favor INTEGER NOT NULL DEFAULT 0,
    votos_contra INTEGER NOT NULL DEFAULT 0,
    abstenciones INTEGER NOT NULL DEFAULT 0,
    porcentaje_aprobacion NUMERIC(5,2),
    resultado VARCHAR(30) NOT NULL DEFAULT 'Pendiente',
    fecha_apertura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_cierre TIMESTAMP,

    CONSTRAINT fk_resultado_votacion
        FOREIGN KEY (id_votacion)
        REFERENCES votacion(id_votacion)
        ON DELETE CASCADE,

    CONSTRAINT fk_resultado_mayoria
        FOREIGN KEY (id_tipo_mayoria_requerida)
        REFERENCES catalogo_tipo_mayoria_requerida(id_tipo_mayoria_requerida)
        ON DELETE RESTRICT,

    CONSTRAINT fk_resultado_tipo_votacion
        FOREIGN KEY (id_tipo_votacion)
        REFERENCES catalogo_tipo_votacion(id_tipo_votacion)
        ON DELETE RESTRICT,

    CONSTRAINT chk_resultado_motor_votacion
        CHECK (resultado IN ('Aprobada', 'Rechazada', 'Pendiente', 'Anulada')),

    CONSTRAINT chk_conteos_resultado_no_negativos
        CHECK (
            total_presentes >= 0
            AND total_votos >= 0
            AND votos_favor >= 0
            AND votos_contra >= 0
            AND abstenciones >= 0
        ),

    CONSTRAINT chk_fechas_resultado_votacion
        CHECK (fecha_cierre IS NULL OR fecha_cierre >= fecha_apertura)
);

CREATE TABLE IF NOT EXISTS voto_asambleista (
    id_voto_asambleista INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_votacion INTEGER NOT NULL,
    id_asambleista INTEGER NOT NULL,
    id_tipo_voto INTEGER NOT NULL,
    codigo_voto_anonimo VARCHAR(64) DEFAULT MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT),
    fecha_voto TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_voto_votacion
        FOREIGN KEY (id_votacion)
        REFERENCES votacion(id_votacion)
        ON DELETE CASCADE,

    CONSTRAINT fk_voto_asambleista
        FOREIGN KEY (id_asambleista)
        REFERENCES asambleista(id_asambleista)
        ON DELETE RESTRICT,

    CONSTRAINT fk_voto_tipo
        FOREIGN KEY (id_tipo_voto)
        REFERENCES catalogo_tipo_voto(id_tipo_voto)
        ON DELETE RESTRICT,

    CONSTRAINT uq_voto_asambleista
        UNIQUE (id_votacion, id_asambleista)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_resultado_votacion ON resultado_votacion(id_votacion);
CREATE INDEX IF NOT EXISTS idx_resultado_mayoria ON resultado_votacion(id_tipo_mayoria_requerida);
CREATE INDEX IF NOT EXISTS idx_voto_asambleista_votacion ON voto_asambleista(id_votacion);
CREATE INDEX IF NOT EXISTS idx_voto_asambleista_asambleista ON voto_asambleista(id_asambleista);
CREATE INDEX IF NOT EXISTS idx_voto_asambleista_tipo ON voto_asambleista(id_tipo_voto);

-- =====================================================
-- 11. BITÁCORA DE AUDITORÍA FORENSE - ISSUE #13
-- =====================================================

ALTER TABLE sys_log_auditoria
    ADD COLUMN IF NOT EXISTS usuario_bd TEXT DEFAULT CURRENT_USER,
    ADD COLUMN IF NOT EXISTS operacion VARCHAR(20),
    ADD COLUMN IF NOT EXISTS registro_pk TEXT,
    ADD COLUMN IF NOT EXISTS datos_antes JSONB,
    ADD COLUMN IF NOT EXISTS datos_despues JSONB,
    ADD COLUMN IF NOT EXISTS fecha_hora_servidor TIMESTAMP DEFAULT CLOCK_TIMESTAMP(),
    ADD COLUMN IF NOT EXISTS nivel_riesgo VARCHAR(20) DEFAULT 'Normal',
    ADD COLUMN IF NOT EXISTS modulo_origen VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_log_auditoria_tabla
ON sys_log_auditoria(tabla_afectada);

CREATE INDEX IF NOT EXISTS idx_log_auditoria_fecha
ON sys_log_auditoria(fecha_hora_servidor);

CREATE INDEX IF NOT EXISTS idx_log_auditoria_usuario
ON sys_log_auditoria(id_usuario);

CREATE INDEX IF NOT EXISTS idx_log_auditoria_operacion
ON sys_log_auditoria(operacion);

CREATE OR REPLACE VIEW v_auditoria_forense AS
SELECT
    id_log,
    id_usuario,
    usuario_bd,
    accion,
    operacion,
    tabla_afectada,
    registro_pk,
    modulo_origen,
    nivel_riesgo,
    ip_origen,
    fecha_hora_servidor,
    datos_antes,
    datos_despues,
    detalle
FROM sys_log_auditoria
ORDER BY fecha_hora_servidor DESC;

-- ========================================================
-- 12. COMPILADOR NORMATIVO Y LEYENDAS LEGALES - ISSUE #6
-- ========================================================

CREATE TABLE IF NOT EXISTS leyenda_nota_condicional (
    id_leyenda INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    contenido TEXT NOT NULL,
    id_etapa_propuesta INTEGER,
    id_estado_propuesta INTEGER,
    id_origen_propuesta INTEGER,
    orden_por_defecto INTEGER DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_leyenda_etapa
        FOREIGN KEY (id_etapa_propuesta)
        REFERENCES catalogo_etapa_propuesta(id_etapa_propuesta)
        ON DELETE SET NULL,

    CONSTRAINT fk_leyenda_estado_propuesta
        FOREIGN KEY (id_estado_propuesta)
        REFERENCES catalogo_estado_propuesta(id_estado_propuesta)
        ON DELETE SET NULL,

    CONSTRAINT fk_leyenda_origen
        FOREIGN KEY (id_origen_propuesta)
        REFERENCES catalogo_origen_propuesta(id_origen_propuesta)
        ON DELETE SET NULL,

    CONSTRAINT chk_codigo_leyenda_no_vacio
        CHECK (BTRIM(codigo) <> ''),

    CONSTRAINT chk_titulo_leyenda_no_vacio
        CHECK (BTRIM(titulo) <> ''),

    CONSTRAINT chk_contenido_leyenda_no_vacio
        CHECK (BTRIM(contenido) <> '')
);

CREATE TABLE IF NOT EXISTS propuesta_leyenda (
    id_propuesta_leyenda INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_propuesta INTEGER NOT NULL,
    id_leyenda INTEGER NOT NULL,
    orden_aparicion INTEGER DEFAULT 0,
    fecha_aplicacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_propuesta_leyenda_propuesta
        FOREIGN KEY (id_propuesta)
        REFERENCES propuesta(id_propuesta)
        ON DELETE CASCADE,

    CONSTRAINT fk_propuesta_leyenda_leyenda
        FOREIGN KEY (id_leyenda)
        REFERENCES leyenda_nota_condicional(id_leyenda)
        ON DELETE RESTRICT,

    CONSTRAINT uq_propuesta_leyenda
        UNIQUE (id_propuesta, id_leyenda),

    CONSTRAINT chk_orden_propuesta_leyenda
        CHECK (orden_aparicion >= 0)
);

ALTER TABLE propuesta
    ADD COLUMN IF NOT EXISTS id_origen_propuesta INTEGER,
    ADD COLUMN IF NOT EXISTS id_etapa_propuesta INTEGER,
    ADD COLUMN IF NOT EXISTS id_propuesta_base INTEGER,
    ADD COLUMN IF NOT EXISTS numero_resolucion VARCHAR(50),
    ADD COLUMN IF NOT EXISTS fecha_aprobacion DATE;

ALTER TABLE propuesta
    ADD CONSTRAINT fk_propuesta_origen
        FOREIGN KEY (id_origen_propuesta)
        REFERENCES catalogo_origen_propuesta(id_origen_propuesta)
        ON DELETE SET NULL;

ALTER TABLE propuesta
    ADD CONSTRAINT fk_propuesta_etapa
        FOREIGN KEY (id_etapa_propuesta)
        REFERENCES catalogo_etapa_propuesta(id_etapa_propuesta)
        ON DELETE SET NULL;

ALTER TABLE propuesta
    ADD CONSTRAINT fk_propuesta_base
        FOREIGN KEY (id_propuesta_base)
        REFERENCES propuesta(id_propuesta)
        ON DELETE SET NULL;

ALTER TABLE propuesta
    ADD CONSTRAINT chk_numero_resolucion_formato
        CHECK (
            numero_resolucion IS NULL
            OR numero_resolucion ~ '^AIR-RES-[0-9]{3}-[0-9]{4}$'
        );

-- Índices
CREATE INDEX IF NOT EXISTS idx_propuesta_origen
ON propuesta(id_origen_propuesta);

CREATE INDEX IF NOT EXISTS idx_propuesta_etapa
ON propuesta(id_etapa_propuesta);

CREATE INDEX IF NOT EXISTS idx_propuesta_base
ON propuesta(id_propuesta_base);

CREATE INDEX IF NOT EXISTS idx_propuesta_resolucion
ON propuesta(numero_resolucion);

CREATE INDEX IF NOT EXISTS idx_leyenda_origen
ON leyenda_nota_condicional(id_origen_propuesta);

CREATE INDEX IF NOT EXISTS idx_leyenda_etapa
ON leyenda_nota_condicional(id_etapa_propuesta);

CREATE INDEX IF NOT EXISTS idx_leyenda_estado
ON leyenda_nota_condicional(id_estado_propuesta);

CREATE INDEX IF NOT EXISTS idx_propuesta_leyenda_propuesta
ON propuesta_leyenda(id_propuesta);

-- =========================================================
-- 13. VISOR DE VIGENCIA / COMPILADOR HISTÓRICO - ISSUE #16
-- =========================================================

ALTER TABLE elemento_normativo
    ADD COLUMN IF NOT EXISTS id_propuesta_origen INTEGER,
    ADD COLUMN IF NOT EXISTS id_votacion_origen INTEGER,
    ADD COLUMN IF NOT EXISTS observacion_vigencia TEXT;

ALTER TABLE elemento_normativo
    ADD CONSTRAINT fk_elemento_propuesta_origen
        FOREIGN KEY (id_propuesta_origen)
        REFERENCES propuesta(id_propuesta)
        ON DELETE SET NULL;

ALTER TABLE elemento_normativo
    ADD CONSTRAINT fk_elemento_votacion_origen
        FOREIGN KEY (id_votacion_origen)
        REFERENCES votacion(id_votacion)
        ON DELETE SET NULL;

-- Índices
CREATE INDEX IF NOT EXISTS idx_elemento_fechas_vigencia
ON elemento_normativo (
    id_reglamento,
    fecha_inicio_vigencia,
    fecha_fin_vigencia
);

CREATE INDEX IF NOT EXISTS idx_elemento_propuesta_origen
ON elemento_normativo(id_propuesta_origen);

CREATE INDEX IF NOT EXISTS idx_elemento_votacion_origen
ON elemento_normativo(id_votacion_origen);

-- =========================================================
-- 14. GENERADOR DE ATESTADOS / CERTIFICACIONES - ISSUE #17
-- =========================================================

CREATE TABLE IF NOT EXISTS control_folio (
    id_control INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    anio INTEGER NOT NULL,
    ultimo_numero INTEGER DEFAULT 0,
    prefijo VARCHAR(10) DEFAULT 'DAIR',
    formato VARCHAR(30) DEFAULT 'DAIR-{anio}-{numero}',
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_control_folio_anio_prefijo
        UNIQUE (anio, prefijo),

    CONSTRAINT chk_control_folio_anio
        CHECK (anio >= 2000),

    CONSTRAINT chk_control_folio_numero
        CHECK (ultimo_numero >= 0)
);

CREATE TABLE IF NOT EXISTS solicitud_certificacion (
    id_solicitud INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_asambleista INTEGER NOT NULL,
    fecha_solicitud DATE NOT NULL DEFAULT CURRENT_DATE,
    periodo_desde DATE,
    periodo_hasta DATE,
    estado VARCHAR(20) DEFAULT 'Pendiente',
    observaciones TEXT,
    id_usuario_solicitante INTEGER,
    fecha_respuesta DATE,

    CONSTRAINT fk_solicitud_asambleista
        FOREIGN KEY (id_asambleista)
        REFERENCES asambleista(id_asambleista)
        ON DELETE RESTRICT,

    CONSTRAINT fk_solicitud_usuario
        FOREIGN KEY (id_usuario_solicitante)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE SET NULL,

    CONSTRAINT chk_estado_solicitud_certificacion
        CHECK (estado IN ('Pendiente', 'En Proceso', 'Completada', 'Rechazada')),

    CONSTRAINT chk_periodo_solicitud
        CHECK (periodo_hasta IS NULL OR periodo_desde IS NULL OR periodo_hasta >= periodo_desde)
);

CREATE TABLE IF NOT EXISTS certificacion_emitida (
    id_certificacion INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_solicitud INTEGER,
    id_asambleista INTEGER NOT NULL,
    folio_unico VARCHAR(50) UNIQUE NOT NULL,
    hash_seguridad VARCHAR(64) NOT NULL,
    fecha_emision DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_emision TIME DEFAULT CURRENT_TIME,
    contenido_json JSONB NOT NULL,
    url_pdf VARCHAR(500),
    estado VARCHAR(20) DEFAULT 'Activa',
    motivo_anulacion TEXT,
    id_usuario_secretaria INTEGER NOT NULL,
    id_certificacion_sustituye INTEGER,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_certificacion_solicitud
        FOREIGN KEY (id_solicitud)
        REFERENCES solicitud_certificacion(id_solicitud)
        ON DELETE SET NULL,

    CONSTRAINT fk_certificacion_asambleista
        FOREIGN KEY (id_asambleista)
        REFERENCES asambleista(id_asambleista)
        ON DELETE RESTRICT,

    CONSTRAINT fk_certificacion_usuario
        FOREIGN KEY (id_usuario_secretaria)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE RESTRICT,

    CONSTRAINT fk_certificacion_sustituye
        FOREIGN KEY (id_certificacion_sustituye)
        REFERENCES certificacion_emitida(id_certificacion)
        ON DELETE SET NULL,

    CONSTRAINT chk_estado_certificacion
        CHECK (estado IN ('Activa', 'Anulada', 'Suspendida')),

    CONSTRAINT chk_hash_sha256
        CHECK (hash_seguridad ~ '^[a-f0-9]{64}$')
);

CREATE TABLE IF NOT EXISTS anulacion_certificacion (
    id_anulacion INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_certificacion INTEGER NOT NULL,
    motivo TEXT NOT NULL,
    fecha_anulacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario_anulacion INTEGER NOT NULL,
    justificacion_detalle TEXT,
    id_certificacion_sustituta INTEGER,

    CONSTRAINT fk_anulacion_certificacion
        FOREIGN KEY (id_certificacion)
        REFERENCES certificacion_emitida(id_certificacion)
        ON DELETE CASCADE,

    CONSTRAINT fk_anulacion_usuario
        FOREIGN KEY (id_usuario_anulacion)
        REFERENCES sys_usuario(id_usuario)
        ON DELETE RESTRICT,

    CONSTRAINT fk_anulacion_sustituta
        FOREIGN KEY (id_certificacion_sustituta)
        REFERENCES certificacion_emitida(id_certificacion)
        ON DELETE SET NULL,

    CONSTRAINT chk_motivo_anulacion_no_vacio
        CHECK (BTRIM(motivo) <> '')
);

CREATE TABLE IF NOT EXISTS certificacion_detalle (
    id_detalle INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_certificacion INTEGER NOT NULL,
    tipo_elemento VARCHAR(50) NOT NULL,
    id_referencia INTEGER NOT NULL,
    descripcion TEXT,
    orden_aparicion INTEGER DEFAULT 0,
    metadata JSONB,

    CONSTRAINT fk_certificacion_detalle
        FOREIGN KEY (id_certificacion)
        REFERENCES certificacion_emitida(id_certificacion)
        ON DELETE CASCADE,

    CONSTRAINT chk_tipo_elemento_certificacion
        CHECK (tipo_elemento IN ('Sesion', 'Acta', 'Propuesta', 'Comision', 'Votacion', 'Nombramiento', 'Asistencia')),

    CONSTRAINT chk_orden_detalle_certificacion
        CHECK (orden_aparicion >= 0)
);

CREATE TABLE IF NOT EXISTS verificacion_externa (
    id_verificacion INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    id_certificacion INTEGER NOT NULL,
    codigo_verificacion VARCHAR(80) UNIQUE NOT NULL,
    url_verificacion VARCHAR(500),
    qr_code TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    veces_verificado INTEGER DEFAULT 0,
    ultima_verificacion TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,

    CONSTRAINT fk_verificacion_certificacion
        FOREIGN KEY (id_certificacion)
        REFERENCES certificacion_emitida(id_certificacion)
        ON DELETE CASCADE,

    CONSTRAINT chk_verificaciones_no_negativas
        CHECK (veces_verificado >= 0)
);

ALTER TABLE solicitud_certificacion
    ADD COLUMN IF NOT EXISTS id_certificacion_generada INTEGER;

ALTER TABLE solicitud_certificacion
    ADD CONSTRAINT fk_solicitud_certificacion_generada
        FOREIGN KEY (id_certificacion_generada)
        REFERENCES certificacion_emitida(id_certificacion)
        ON DELETE SET NULL;

-- Índices
CREATE INDEX IF NOT EXISTS idx_certificacion_folio ON certificacion_emitida(folio_unico);
CREATE INDEX IF NOT EXISTS idx_certificacion_asambleista ON certificacion_emitida(id_asambleista);
CREATE INDEX IF NOT EXISTS idx_certificacion_fecha ON certificacion_emitida(fecha_emision);
CREATE INDEX IF NOT EXISTS idx_certificacion_estado ON certificacion_emitida(estado);
CREATE INDEX IF NOT EXISTS idx_certificacion_solicitud ON certificacion_emitida(id_solicitud);

CREATE INDEX IF NOT EXISTS idx_detalle_certificacion ON certificacion_detalle(id_certificacion);
CREATE INDEX IF NOT EXISTS idx_detalle_tipo ON certificacion_detalle(tipo_elemento);

CREATE INDEX IF NOT EXISTS idx_verificacion_codigo ON verificacion_externa(codigo_verificacion);
CREATE INDEX IF NOT EXISTS idx_verificacion_certificacion ON verificacion_externa(id_certificacion);

CREATE INDEX IF NOT EXISTS idx_solicitud_asambleista ON solicitud_certificacion(id_asambleista);
CREATE INDEX IF NOT EXISTS idx_solicitud_estado ON solicitud_certificacion(estado);

-- =====================================================
-- 15. FUNCIONES Y TRIGGERS PARA REGLAS DE NEGOCIO
-- =====================================================

CREATE OR REPLACE FUNCTION fn_bitacora_asambleista()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.cedula <> NEW.cedula
       OR OLD.nombre <> NEW.nombre
       OR COALESCE(OLD.correo_institucional, '') <> COALESCE(NEW.correo_institucional, '') THEN

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
            'Actualización automática de datos personales'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_auditoria_general()
RETURNS TRIGGER AS $$
DECLARE
    v_id_usuario INTEGER;
    v_registro_id TEXT;
BEGIN
    BEGIN
        v_id_usuario := NULLIF(current_setting('app.current_user_id', TRUE), '')::INTEGER;
    EXCEPTION WHEN OTHERS THEN
        v_id_usuario := NULL;
    END;

    IF TG_TABLE_NAME = 'asambleista' THEN
        IF TG_OP = 'DELETE' THEN v_registro_id := OLD.id_asambleista::TEXT; ELSE v_registro_id := NEW.id_asambleista::TEXT; END IF;
    ELSIF TG_TABLE_NAME = 'elemento_normativo' THEN
        IF TG_OP = 'DELETE' THEN v_registro_id := OLD.id_elemento::TEXT; ELSE v_registro_id := NEW.id_elemento::TEXT; END IF;
    ELSIF TG_TABLE_NAME = 'nombramiento' THEN
        IF TG_OP = 'DELETE' THEN v_registro_id := OLD.id_nombramiento::TEXT; ELSE v_registro_id := NEW.id_nombramiento::TEXT; END IF;
    ELSIF TG_TABLE_NAME = 'reforma_aplicada' THEN
        IF TG_OP = 'DELETE' THEN v_registro_id := OLD.id_reforma::TEXT; ELSE v_registro_id := NEW.id_reforma::TEXT; END IF;
    ELSE
        v_registro_id := 'N/A';
    END IF;

    INSERT INTO sys_log_auditoria(id_usuario, accion, tabla_afectada, detalle)
    VALUES (v_id_usuario, TG_OP, TG_TABLE_NAME, 'Operación ' || TG_OP || '. ID: ' || COALESCE(v_registro_id, 'N/A'));

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_versionar_elemento_normativo()
RETURNS TRIGGER AS $$
BEGIN
    -- Si se inserta una nueva versión vigente, la versión vigente anterior, padre y etiqueta pasa automáticamente a Histórico.
    IF NEW.id_estado_vigencia = 1 AND NEW.fecha_fin_vigencia IS NULL THEN
        UPDATE elemento_normativo
        SET id_estado_vigencia = 2,
            fecha_fin_vigencia = NEW.fecha_inicio_vigencia - INTERVAL '1 day'
        WHERE id_reglamento = NEW.id_reglamento
          AND COALESCE(id_elemento_padre, 0) = COALESCE(NEW.id_elemento_padre, 0)
          AND numero_etiqueta = NEW.numero_etiqueta
          AND id_estado_vigencia = 1
          AND fecha_fin_vigencia IS NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_validar_traslape_nombramiento()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'Activo' THEN
        IF EXISTS (
            SELECT 1
            FROM nombramiento n
            WHERE n.id_asambleista = NEW.id_asambleista
              AND n.id_sector = NEW.id_sector
              AND n.estado = 'Activo'
              AND n.id_nombramiento <> COALESCE(NEW.id_nombramiento, -1)
              AND NEW.fecha_inicio <= COALESCE(n.fecha_fin, DATE '9999-12-31')
              AND COALESCE(NEW.fecha_fin, DATE '9999-12-31') >= n.fecha_inicio
        ) THEN
            RAISE EXCEPTION 'El asambleísta ya tiene un nombramiento activo en ese sector durante ese periodo.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_versionar_elemento_normativo
BEFORE INSERT ON elemento_normativo
FOR EACH ROW
EXECUTE FUNCTION fn_versionar_elemento_normativo();

CREATE TRIGGER tg_validar_traslape_nombramiento
BEFORE INSERT OR UPDATE ON nombramiento
FOR EACH ROW
EXECUTE FUNCTION fn_validar_traslape_nombramiento();

CREATE TRIGGER tg_bitacora_asambleista
AFTER UPDATE ON asambleista
FOR EACH ROW
EXECUTE FUNCTION fn_bitacora_asambleista();

-- Triggers de auditoría básica vieja:
-- CREATE TRIGGER tg_auditoria_asambleista
-- AFTER INSERT OR UPDATE OR DELETE ON asambleista
-- FOR EACH ROW
-- EXECUTE FUNCTION fn_auditoria_general();

-- CREATE TRIGGER tg_auditoria_elemento_normativo
-- AFTER INSERT OR UPDATE OR DELETE ON elemento_normativo
-- FOR EACH ROW
-- EXECUTE FUNCTION fn_auditoria_general();

-- CREATE TRIGGER tg_auditoria_nombramiento
-- AFTER INSERT OR UPDATE OR DELETE ON nombramiento
-- FOR EACH ROW
-- EXECUTE FUNCTION fn_auditoria_general();

-- CREATE TRIGGER tg_auditoria_reforma_aplicada
-- AFTER INSERT OR UPDATE OR DELETE ON reforma_aplicada
-- FOR EACH ROW
-- EXECUTE FUNCTION fn_auditoria_general();

-- Sprint 3:

CREATE OR REPLACE FUNCTION fn_validar_traslape_integrante_comision()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'Activo' THEN
        IF EXISTS (
            SELECT 1
            FROM integrante_comision ic
            WHERE ic.id_comision = NEW.id_comision
              AND ic.id_asambleista = NEW.id_asambleista
              AND ic.estado = 'Activo'
              AND ic.id_integrante_comision <> COALESCE(NEW.id_integrante_comision, -1)
              AND NEW.fecha_ingreso_nombramiento <= COALESCE(ic.fecha_fin_nombramiento, DATE '9999-12-31')
              AND COALESCE(NEW.fecha_fin_nombramiento, DATE '9999-12-31') >= ic.fecha_ingreso_nombramiento
        ) THEN
            RAISE EXCEPTION 'El asambleísta ya tiene un nombramiento activo en esa comisión durante ese periodo.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_bitacora_integrante_comision()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO bitacora_integrante_comision (
        id_integrante_comision,
        id_comision,
        id_asambleista,
        id_rol_comision,
        fecha_ingreso_nombramiento,
        fecha_fin_nombramiento,
        estado,
        accion
    )
    VALUES (
        COALESCE(NEW.id_integrante_comision, OLD.id_integrante_comision),
        COALESCE(NEW.id_comision, OLD.id_comision),
        COALESCE(NEW.id_asambleista, OLD.id_asambleista),
        COALESCE(NEW.id_rol_comision, OLD.id_rol_comision),
        COALESCE(NEW.fecha_ingreso_nombramiento, OLD.fecha_ingreso_nombramiento),
        COALESCE(NEW.fecha_fin_nombramiento, OLD.fecha_fin_nombramiento),
        COALESCE(NEW.estado, OLD.estado),
        TG_OP
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_validar_punto_agenda_comision()
RETURNS TRIGGER AS $$
DECLARE
    v_comision_sesion INTEGER;
    v_comision_proposito INTEGER;
BEGIN
    SELECT id_comision
    INTO v_comision_sesion
    FROM sesion_comision
    WHERE id_sesion_comision = NEW.id_sesion_comision;

    SELECT id_comision
    INTO v_comision_proposito
    FROM proposito_comision
    WHERE id_proposito_comision = NEW.id_proposito_comision;

    IF v_comision_sesion <> v_comision_proposito THEN
        RAISE EXCEPTION 'El propósito de comisión no pertenece a la misma comisión de la sesión.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_validar_informe_directorio()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM proposito_comision pc
        WHERE pc.id_comision = NEW.id_comision
          AND pc.id_propuesta = NEW.id_propuesta
    ) THEN
        RAISE EXCEPTION 'La propuesta del informe no está asociada a esa comisión.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_validar_asistencia_comision()
RETURNS TRIGGER AS $$
DECLARE
    v_comision_sesion INTEGER;
    v_fecha_sesion DATE;
BEGIN
    SELECT id_comision, fecha_hora::DATE
    INTO v_comision_sesion, v_fecha_sesion
    FROM sesion_comision
    WHERE id_sesion_comision = NEW.id_sesion_comision;

    IF v_comision_sesion <> NEW.id_comision THEN
        RAISE EXCEPTION 'La sesión indicada no pertenece a la comisión indicada.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM integrante_comision ic
        WHERE ic.id_comision = NEW.id_comision
          AND ic.id_asambleista = NEW.id_asambleista
          AND ic.estado = 'Activo'
          AND ic.fecha_ingreso_nombramiento <= v_fecha_sesion
          AND COALESCE(ic.fecha_fin_nombramiento, DATE '9999-12-31') >= v_fecha_sesion
    ) THEN
        RAISE EXCEPTION 'Solo se puede registrar asistencia de integrantes activos de la comisión en la fecha de la sesión.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_validar_traslape_integrante_comision
BEFORE INSERT OR UPDATE ON integrante_comision
FOR EACH ROW
EXECUTE FUNCTION fn_validar_traslape_integrante_comision();

CREATE TRIGGER tg_bitacora_integrante_comision
AFTER INSERT OR UPDATE OR DELETE ON integrante_comision
FOR EACH ROW
EXECUTE FUNCTION fn_bitacora_integrante_comision();

CREATE TRIGGER tg_validar_punto_agenda_comision
BEFORE INSERT OR UPDATE ON punto_agenda_sesion_comision
FOR EACH ROW
EXECUTE FUNCTION fn_validar_punto_agenda_comision();

CREATE TRIGGER tg_validar_informe_directorio
BEFORE INSERT OR UPDATE ON informe_directorio
FOR EACH ROW
EXECUTE FUNCTION fn_validar_informe_directorio();

CREATE TRIGGER tg_validar_asistencia_comision
BEFORE INSERT OR UPDATE ON asistencia_sesion_comision
FOR EACH ROW
EXECUTE FUNCTION fn_validar_asistencia_comision();

CREATE OR REPLACE FUNCTION fn_validar_resumen_votacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.total_votantes :=
        COALESCE(NEW.votos_favor, 0)
        + COALESCE(NEW.votos_contra, 0)
        + COALESCE(NEW.votos_abstencion, 0);

    IF NEW.estado_acuerdo = 'Firmado' AND NEW.fecha_firma_acuerdo IS NULL THEN
        NEW.fecha_firma_acuerdo := CURRENT_TIMESTAMP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_validar_resumen_votacion
BEFORE INSERT OR UPDATE ON votacion
FOR EACH ROW
EXECUTE FUNCTION fn_validar_resumen_votacion();

CREATE OR REPLACE FUNCTION fn_bitacora_estado_votacion()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.estado_acuerdo <> NEW.estado_acuerdo THEN
        INSERT INTO bitacora_estado_votacion (
            id_votacion,
            estado_anterior,
            estado_nuevo,
            id_usuario,
            observaciones
        )
        VALUES (
            NEW.id_votacion,
            OLD.estado_acuerdo,
            NEW.estado_acuerdo,
            NEW.id_usuario_firma,
            'Cambio automático de estado de acuerdo'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_bitacora_estado_votacion
AFTER UPDATE ON votacion
FOR EACH ROW
EXECUTE FUNCTION fn_bitacora_estado_votacion();

CREATE OR REPLACE FUNCTION fn_total_asambleistas_activos(p_fecha DATE)
RETURNS INTEGER AS $$
DECLARE
    v_total INTEGER;
BEGIN
    SELECT COUNT(DISTINCT n.id_asambleista)
    INTO v_total
    FROM nombramiento n
    WHERE n.estado = 'Activo'
      AND n.fecha_inicio <= p_fecha
      AND COALESCE(n.fecha_fin, DATE '9999-12-31') >= p_fecha;

    RETURN COALESCE(v_total, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_asistentes_para_quorum(p_id_sesion INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_total INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM asistencia_sesion_plenaria asp
    INNER JOIN catalogo_estado_asistencia cea
        ON asp.id_estado_asistencia = cea.id_estado_asistencia
    WHERE asp.id_sesion = p_id_sesion
      AND cea.nombre IN ('Presente', 'Retardo');

    RETURN COALESCE(v_total, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_quorum_requerido(p_id_sesion INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_total_asambleistas INTEGER;
    v_porcentaje NUMERIC(5,2);
    v_requerido INTEGER;
BEGIN
    SELECT
        COALESCE(s.total_asambleistas, fn_total_asambleistas_activos(s.fecha)),
        cts.quorum_porcentaje
    INTO v_total_asambleistas, v_porcentaje
    FROM sesion s
    INNER JOIN catalogo_tipo_sesion cts
        ON s.id_tipo_sesion = cts.id_tipo_sesion
    WHERE s.id_sesion = p_id_sesion;

    IF v_total_asambleistas IS NULL OR v_total_asambleistas = 0 THEN
        RAISE EXCEPTION 'No se puede calcular quórum: no hay asambleístas activos para la fecha de la sesión.';
    END IF;

    v_requerido := CEIL(v_total_asambleistas * (v_porcentaje / 100.0));

    RETURN v_requerido;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_validar_quorum(p_id_sesion INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    v_presentes INTEGER;
    v_requerido INTEGER;
BEGIN
    v_presentes := fn_asistentes_para_quorum(p_id_sesion);
    v_requerido := fn_quorum_requerido(p_id_sesion);

    RETURN v_presentes >= v_requerido;
END;
$$ LANGUAGE plpgsql;

-- Calcular Resultado de Votación
CREATE OR REPLACE FUNCTION fn_calcular_resultado_votacion(
    p_votos_favor INTEGER,
    p_votos_contra INTEGER,
    p_tipo_mayoria VARCHAR
)
RETURNS VARCHAR AS $$
DECLARE
    v_total INTEGER;
    v_umbral NUMERIC;
BEGIN
    v_total := p_votos_favor + p_votos_contra;

    IF v_total = 0 THEN
        RETURN 'Pendiente';
    END IF;

    IF p_tipo_mayoria = 'Calificada' THEN
        v_umbral := v_total * (2.0 / 3.0);
        IF p_votos_favor >= CEIL(v_umbral) THEN
            RETURN 'Aprobada';
        ELSE
            RETURN 'Rechazada';
        END IF;
    ELSE
        IF p_votos_favor > p_votos_contra THEN
            RETURN 'Aprobada';
        ELSIF p_votos_favor = p_votos_contra THEN
            RETURN 'Empate';
        ELSE
            RETURN 'Rechazada';
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Actualizar Resumen de Quórum en Sesión
CREATE OR REPLACE FUNCTION fn_actualizar_resumen_quorum()
RETURNS TRIGGER AS $$
DECLARE
    v_id_sesion INTEGER;
    v_total INTEGER;
    v_requerido INTEGER;
BEGIN
    v_id_sesion := COALESCE(NEW.id_sesion, OLD.id_sesion);

    SELECT fn_total_asambleistas_activos(fecha)
    INTO v_total
    FROM sesion
    WHERE id_sesion = v_id_sesion;

    v_requerido := fn_quorum_requerido(v_id_sesion);

    UPDATE sesion
    SET total_asambleistas = v_total,
        quorum_requerido   = v_requerido
    WHERE id_sesion = v_id_sesion;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_actualizar_resumen_quorum
AFTER INSERT OR UPDATE OR DELETE ON asistencia_sesion_plenaria
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_resumen_quorum();

-- Bloquear Votación sin Quórum
CREATE OR REPLACE FUNCTION fn_bloquear_votacion_sin_quorum()
RETURNS TRIGGER AS $$
DECLARE
    v_presentes INTEGER;
    v_requerido INTEGER;
BEGIN
    v_presentes := fn_asistentes_para_quorum(NEW.id_sesion);
    v_requerido := fn_quorum_requerido(NEW.id_sesion);

    IF v_presentes < v_requerido THEN
        RAISE EXCEPTION
            'Quórum insuficiente. Presentes: %, requeridos: %. No se puede registrar la votación.',
            v_presentes,
            v_requerido;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_validar_quorum
BEFORE INSERT OR UPDATE ON votacion
FOR EACH ROW
EXECUTE FUNCTION fn_bloquear_votacion_sin_quorum();

CREATE OR REPLACE FUNCTION fn_calcular_resultado_votacion_detalle(
    p_votos_favor INTEGER,
    p_votos_contra INTEGER,
    p_total_presentes INTEGER,
    p_tipo_mayoria VARCHAR
)
RETURNS VARCHAR AS $$
DECLARE
    v_umbral INTEGER;
BEGIN
    IF p_total_presentes IS NULL OR p_total_presentes = 0 THEN
        RETURN 'Pendiente';
    END IF;

    IF p_tipo_mayoria = 'Calificada' THEN
        v_umbral := CEIL(p_total_presentes * 0.6667);

        IF p_votos_favor >= v_umbral THEN
            RETURN 'Aprobada';
        ELSE
            RETURN 'Rechazada';
        END IF;
    ELSE
        IF p_votos_favor > p_votos_contra THEN
            RETURN 'Aprobada';
        ELSE
            RETURN 'Rechazada';
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_validar_voto_asambleista()
RETURNS TRIGGER AS $$
DECLARE
    v_id_sesion INTEGER;
BEGIN
    SELECT id_sesion
    INTO v_id_sesion
    FROM votacion
    WHERE id_votacion = NEW.id_votacion;

    IF v_id_sesion IS NULL THEN
        RAISE EXCEPTION 'La votación indicada no existe.';
    END IF;

    IF NOT fn_validar_quorum(v_id_sesion) THEN
        RAISE EXCEPTION 'No se puede registrar el voto porque la sesión no tiene quórum válido.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM resultado_votacion rv
        WHERE rv.id_votacion = NEW.id_votacion
          AND rv.fecha_cierre IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'No se puede votar porque la votación ya está cerrada.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM asistencia_sesion_plenaria asp
        JOIN catalogo_estado_asistencia cea
            ON asp.id_estado_asistencia = cea.id_estado_asistencia
        WHERE asp.id_sesion = v_id_sesion
          AND asp.id_asambleista = NEW.id_asambleista
          AND cea.nombre IN ('Presente', 'Retardo')
    ) THEN
        RAISE EXCEPTION 'Solo pueden votar asambleístas presentes o con retardo registrado.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_recalcular_resultado_votacion(p_id_votacion INTEGER)
RETURNS VOID AS $$
DECLARE
    v_id_sesion INTEGER;
    v_total_presentes INTEGER;
    v_total_votos INTEGER;
    v_favor INTEGER;
    v_contra INTEGER;
    v_abstenciones INTEGER;
    v_porcentaje NUMERIC(5,2);
    v_tipo_mayoria VARCHAR(50);
    v_id_tipo_mayoria INTEGER;
    v_id_tipo_votacion INTEGER;
    v_resultado VARCHAR(30);
BEGIN
    SELECT id_sesion
    INTO v_id_sesion
    FROM votacion
    WHERE id_votacion = p_id_votacion;

    IF v_id_sesion IS NULL THEN
        RETURN;
    END IF;

    v_total_presentes := fn_asistentes_para_quorum(v_id_sesion);

    SELECT COUNT(*)
    INTO v_total_votos
    FROM voto_asambleista
    WHERE id_votacion = p_id_votacion;

    SELECT COUNT(*)
    INTO v_favor
    FROM voto_asambleista va
    JOIN catalogo_tipo_voto ctv ON va.id_tipo_voto = ctv.id_tipo_voto
    WHERE va.id_votacion = p_id_votacion
      AND ctv.nombre = 'Favor';

    SELECT COUNT(*)
    INTO v_contra
    FROM voto_asambleista va
    JOIN catalogo_tipo_voto ctv ON va.id_tipo_voto = ctv.id_tipo_voto
    WHERE va.id_votacion = p_id_votacion
      AND ctv.nombre = 'Contra';

    SELECT COUNT(*)
    INTO v_abstenciones
    FROM voto_asambleista va
    JOIN catalogo_tipo_voto ctv ON va.id_tipo_voto = ctv.id_tipo_voto
    WHERE va.id_votacion = p_id_votacion
      AND ctv.nombre = 'Abstención';

    SELECT
        COALESCE(rv.id_tipo_mayoria_requerida, 1),
        COALESCE(rv.id_tipo_votacion, 1),
        cm.nombre
    INTO v_id_tipo_mayoria, v_id_tipo_votacion, v_tipo_mayoria
    FROM resultado_votacion rv
    JOIN catalogo_tipo_mayoria_requerida cm
        ON rv.id_tipo_mayoria_requerida = cm.id_tipo_mayoria_requerida
    WHERE rv.id_votacion = p_id_votacion;

    IF v_id_tipo_mayoria IS NULL THEN
        v_id_tipo_mayoria := 1;
        v_id_tipo_votacion := 1;
        v_tipo_mayoria := 'Simple';
    END IF;

    IF v_total_presentes = 0 THEN
        v_porcentaje := 0;
    ELSE
        v_porcentaje := ROUND((v_favor::NUMERIC / v_total_presentes::NUMERIC) * 100, 2);
    END IF;

    v_resultado := fn_calcular_resultado_votacion_detalle(
        v_favor,
        v_contra,
        v_total_presentes,
        v_tipo_mayoria
    );

    INSERT INTO resultado_votacion (
        id_votacion,
        id_tipo_mayoria_requerida,
        id_tipo_votacion,
        total_presentes,
        total_votos,
        votos_favor,
        votos_contra,
        abstenciones,
        porcentaje_aprobacion,
        resultado
    )
    VALUES (
        p_id_votacion,
        v_id_tipo_mayoria,
        v_id_tipo_votacion,
        v_total_presentes,
        v_total_votos,
        v_favor,
        v_contra,
        v_abstenciones,
        v_porcentaje,
        v_resultado
    )
    ON CONFLICT (id_votacion) DO UPDATE SET
        total_presentes = EXCLUDED.total_presentes,
        total_votos = EXCLUDED.total_votos,
        votos_favor = EXCLUDED.votos_favor,
        votos_contra = EXCLUDED.votos_contra,
        abstenciones = EXCLUDED.abstenciones,
        porcentaje_aprobacion = EXCLUDED.porcentaje_aprobacion,
        resultado = EXCLUDED.resultado;

    UPDATE votacion
    SET votos_favor = v_favor,
        votos_contra = v_contra,
        votos_abstencion = v_abstenciones,
        total_votantes = v_total_votos,
        resultado = v_resultado
    WHERE id_votacion = p_id_votacion;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_trigger_recalcular_resultado_votacion()
RETURNS TRIGGER AS $$
DECLARE
    v_id_votacion INTEGER;
BEGIN
    v_id_votacion := COALESCE(NEW.id_votacion, OLD.id_votacion);

    PERFORM fn_recalcular_resultado_votacion(v_id_votacion);

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_validar_voto_asambleista
BEFORE INSERT OR UPDATE ON voto_asambleista
FOR EACH ROW
EXECUTE FUNCTION fn_validar_voto_asambleista();

CREATE TRIGGER tg_recalcular_resultado_votacion
AFTER INSERT OR UPDATE OR DELETE ON voto_asambleista
FOR EACH ROW
EXECUTE FUNCTION fn_trigger_recalcular_resultado_votacion();

CREATE OR REPLACE FUNCTION fn_auditoria_forense()
RETURNS TRIGGER AS $$
DECLARE
    v_id_usuario INTEGER;
    v_ip_origen TEXT;
    v_registro_pk TEXT;
    v_modulo TEXT;
    v_riesgo TEXT;
BEGIN
    BEGIN
        v_id_usuario := NULLIF(current_setting('app.current_user_id', TRUE), '')::INTEGER;
    EXCEPTION WHEN OTHERS THEN
        v_id_usuario := NULL;
    END;

    BEGIN
        v_ip_origen := NULLIF(current_setting('app.ip_origen', TRUE), '');
    EXCEPTION WHEN OTHERS THEN
        v_ip_origen := NULL;
    END;

    IF v_ip_origen IS NULL THEN
        v_ip_origen := INET_CLIENT_ADDR()::TEXT;
    END IF;

    IF TG_TABLE_NAME = 'asambleista' THEN
        v_registro_pk := COALESCE(NEW.id_asambleista, OLD.id_asambleista)::TEXT;
        v_modulo := 'Gestión de Asambleístas';
    ELSIF TG_TABLE_NAME = 'nombramiento' THEN
        v_registro_pk := COALESCE(NEW.id_nombramiento, OLD.id_nombramiento)::TEXT;
        v_modulo := 'Nombramientos';
    ELSIF TG_TABLE_NAME = 'propuesta' THEN
        v_registro_pk := COALESCE(NEW.id_propuesta, OLD.id_propuesta)::TEXT;
        v_modulo := 'Propuestas';
    ELSIF TG_TABLE_NAME = 'votacion' THEN
        v_registro_pk := COALESCE(NEW.id_votacion, OLD.id_votacion)::TEXT;
        v_modulo := 'Votaciones';
    ELSIF TG_TABLE_NAME = 'voto_asambleista' THEN
        v_registro_pk := COALESCE(NEW.id_voto_asambleista, OLD.id_voto_asambleista)::TEXT;
        v_modulo := 'Motor de Votaciones';
    ELSIF TG_TABLE_NAME = 'resultado_votacion' THEN
        v_registro_pk := COALESCE(NEW.id_resultado_votacion, OLD.id_resultado_votacion)::TEXT;
        v_modulo := 'Resultado de Votación';
    ELSIF TG_TABLE_NAME = 'elemento_normativo' THEN
        v_registro_pk := COALESCE(NEW.id_elemento, OLD.id_elemento)::TEXT;
        v_modulo := 'Normativa';
    ELSE
        v_registro_pk := 'N/A';
        v_modulo := 'General';
    END IF;

    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        v_riesgo := 'Alto';
    ELSE
        v_riesgo := 'Normal';
    END IF;

    INSERT INTO sys_log_auditoria (
        id_usuario,
        accion,
        operacion,
        tabla_afectada,
        registro_pk,
        detalle,
        ip_origen,
        usuario_bd,
        datos_antes,
        datos_despues,
        fecha_hora_servidor,
        nivel_riesgo,
        modulo_origen
    )
    VALUES (
        v_id_usuario,
        TG_OP,
        TG_OP,
        TG_TABLE_NAME,
        v_registro_pk,
        'Auditoría forense automática. Tabla: ' || TG_TABLE_NAME || ', operación: ' || TG_OP,
        v_ip_origen,
        CURRENT_USER,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN TO_JSONB(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN TO_JSONB(NEW) ELSE NULL END,
        CLOCK_TIMESTAMP(),
        v_riesgo,
        v_modulo
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_auditoria_forense_asambleista
AFTER INSERT OR UPDATE OR DELETE ON asambleista
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE TRIGGER tg_auditoria_forense_nombramiento
AFTER INSERT OR UPDATE OR DELETE ON nombramiento
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE TRIGGER tg_auditoria_forense_elemento_normativo
AFTER INSERT OR UPDATE OR DELETE ON elemento_normativo
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE TRIGGER tg_auditoria_forense_propuesta
AFTER INSERT OR UPDATE OR DELETE ON propuesta
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE TRIGGER tg_auditoria_forense_votacion
AFTER INSERT OR UPDATE OR DELETE ON votacion
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE TRIGGER tg_auditoria_forense_voto_asambleista
AFTER INSERT OR UPDATE OR DELETE ON voto_asambleista
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE TRIGGER tg_auditoria_forense_resultado_votacion
AFTER INSERT OR UPDATE OR DELETE ON resultado_votacion
FOR EACH ROW
EXECUTE FUNCTION fn_auditoria_forense();

CREATE OR REPLACE FUNCTION fn_aplicar_leyendas_propuesta()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO propuesta_leyenda (
        id_propuesta,
        id_leyenda,
        orden_aparicion
    )
    SELECT
        NEW.id_propuesta,
        l.id_leyenda,
        l.orden_por_defecto
    FROM leyenda_nota_condicional l
    WHERE l.activo = TRUE
      AND (
            l.id_origen_propuesta IS NULL
            OR l.id_origen_propuesta = NEW.id_origen_propuesta
          )
      AND (
            l.id_etapa_propuesta IS NULL
            OR l.id_etapa_propuesta = NEW.id_etapa_propuesta
          )
      AND (
            l.id_estado_propuesta IS NULL
            OR l.id_estado_propuesta = NEW.id_estado_propuesta
          )
    ON CONFLICT (id_propuesta, id_leyenda) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_aplicar_leyendas_propuesta
AFTER INSERT OR UPDATE OF id_origen_propuesta, id_etapa_propuesta, id_estado_propuesta ON propuesta
FOR EACH ROW
EXECUTE FUNCTION fn_aplicar_leyendas_propuesta();

CREATE OR REPLACE FUNCTION obtener_texto_vigente_en_fecha(
    p_id_reglamento INTEGER,
    p_fecha_consulta DATE
)
RETURNS JSONB AS $$
DECLARE
    resultado JSONB;
BEGIN
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'id_elemento', e.id_elemento,
                'id_padre', e.id_elemento_padre,
                'nivel', cnr.nombre,
                'numero', e.numero_etiqueta,
                'contenido', e.contenido_texto,
                'orden', e.orden,
                'vigencia_inicio', e.fecha_inicio_vigencia,
                'vigencia_fin', e.fecha_fin_vigencia,
                'estado', cev.nombre,
                'propuesta_origen', p.numero_propuesta,
                'votacion_origen', v.numero_votacion
            )
            ORDER BY cnr.orden, e.orden, e.numero_etiqueta
        ),
        '[]'::jsonb
    )
    INTO resultado
    FROM elemento_normativo e
    JOIN catalogo_nivel_reglamento cnr
        ON e.id_nivel_reglamento = cnr.id_nivel_reglamento
    JOIN catalogo_estado_vigencia cev
        ON e.id_estado_vigencia = cev.id_estado_vigencia
    LEFT JOIN propuesta p
        ON e.id_propuesta_origen = p.id_propuesta
    LEFT JOIN votacion v
        ON e.id_votacion_origen = v.id_votacion
    WHERE e.id_reglamento = p_id_reglamento
      AND e.fecha_inicio_vigencia <= p_fecha_consulta
      AND (
            e.fecha_fin_vigencia IS NULL
            OR e.fecha_fin_vigencia > p_fecha_consulta
          )
    ORDER BY e.orden;

    RETURN resultado;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION obtener_arbol_normativo_vigente(
    p_id_reglamento INTEGER,
    p_fecha_consulta DATE
)
RETURNS TABLE (
    id_elemento INTEGER,
    id_elemento_padre INTEGER,
    nivel TEXT,
    numero_etiqueta VARCHAR,
    contenido_texto TEXT,
    profundidad INTEGER,
    ruta TEXT,
    fecha_inicio_vigencia DATE,
    fecha_fin_vigencia DATE
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE arbol AS (
        SELECT
            e.id_elemento,
            e.id_elemento_padre,
            cnr.nombre::TEXT AS nivel,
            e.numero_etiqueta,
            e.contenido_texto,
            1 AS profundidad,
            e.numero_etiqueta::TEXT AS ruta,
            e.fecha_inicio_vigencia,
            e.fecha_fin_vigencia,
            e.orden
        FROM elemento_normativo e
        JOIN catalogo_nivel_reglamento cnr
            ON e.id_nivel_reglamento = cnr.id_nivel_reglamento
        WHERE e.id_reglamento = p_id_reglamento
          AND e.id_elemento_padre IS NULL
          AND e.fecha_inicio_vigencia <= p_fecha_consulta
          AND (
                e.fecha_fin_vigencia IS NULL
                OR e.fecha_fin_vigencia > p_fecha_consulta
              )

        UNION ALL

        SELECT
            hijo.id_elemento,
            hijo.id_elemento_padre,
            cnr.nombre::TEXT AS nivel,
            hijo.numero_etiqueta,
            hijo.contenido_texto,
            padre.profundidad + 1,
            padre.ruta || ' > ' || hijo.numero_etiqueta,
            hijo.fecha_inicio_vigencia,
            hijo.fecha_fin_vigencia,
            hijo.orden
        FROM elemento_normativo hijo
        JOIN arbol padre
            ON hijo.id_elemento_padre = padre.id_elemento
        JOIN catalogo_nivel_reglamento cnr
            ON hijo.id_nivel_reglamento = cnr.id_nivel_reglamento
        WHERE hijo.fecha_inicio_vigencia <= p_fecha_consulta
          AND (
                hijo.fecha_fin_vigencia IS NULL
                OR hijo.fecha_fin_vigencia > p_fecha_consulta
              )
    )
    SELECT
        a.id_elemento,
        a.id_elemento_padre,
        a.nivel,
        a.numero_etiqueta,
        a.contenido_texto,
        a.profundidad,
        a.ruta,
        a.fecha_inicio_vigencia,
        a.fecha_fin_vigencia
    FROM arbol a
    ORDER BY a.ruta, a.orden;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION obtener_historial_elemento(
    p_id_elemento INTEGER
)
RETURNS JSONB AS $$
DECLARE
    v_reglamento INTEGER;
    v_padre INTEGER;
    v_etiqueta VARCHAR;
    resultado JSONB;
BEGIN
    SELECT id_reglamento, id_elemento_padre, numero_etiqueta
    INTO v_reglamento, v_padre, v_etiqueta
    FROM elemento_normativo
    WHERE id_elemento = p_id_elemento;

    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'id_elemento', e.id_elemento,
                'numero_etiqueta', e.numero_etiqueta,
                'contenido', e.contenido_texto,
                'fecha_inicio_vigencia', e.fecha_inicio_vigencia,
                'fecha_fin_vigencia', e.fecha_fin_vigencia,
                'estado', cev.nombre,
                'propuesta_origen', p.numero_propuesta,
                'votacion_origen', v.numero_votacion,
                'observacion', e.observacion_vigencia
            )
            ORDER BY e.fecha_inicio_vigencia
        ),
        '[]'::jsonb
    )
    INTO resultado
    FROM elemento_normativo e
    JOIN catalogo_estado_vigencia cev
        ON e.id_estado_vigencia = cev.id_estado_vigencia
    LEFT JOIN propuesta p
        ON e.id_propuesta_origen = p.id_propuesta
    LEFT JOIN votacion v
        ON e.id_votacion_origen = v.id_votacion
    WHERE e.id_reglamento = v_reglamento
      AND COALESCE(e.id_elemento_padre, 0) = COALESCE(v_padre, 0)
      AND e.numero_etiqueta = v_etiqueta;

    RETURN resultado;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_generar_folio_certificacion()
RETURNS TEXT AS $$
DECLARE
    v_anio INTEGER;
    v_numero INTEGER;
    v_folio TEXT;
BEGIN
    v_anio := EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER;

    INSERT INTO control_folio (anio, ultimo_numero, prefijo)
    VALUES (v_anio, 0, 'DAIR')
    ON CONFLICT (anio, prefijo) DO NOTHING;

    SELECT ultimo_numero + 1
    INTO v_numero
    FROM control_folio
    WHERE anio = v_anio
      AND prefijo = 'DAIR'
    FOR UPDATE;

    UPDATE control_folio
    SET ultimo_numero = v_numero,
        fecha_actualizacion = CURRENT_TIMESTAMP
    WHERE anio = v_anio
      AND prefijo = 'DAIR';

    v_folio := 'DAIR-' || v_anio::TEXT || '-' || LPAD(v_numero::TEXT, 3, '0');

    RETURN v_folio;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_generar_hash_certificacion(p_contenido JSONB)
RETURNS TEXT AS $$
BEGIN
    RETURN ENCODE(DIGEST(p_contenido::TEXT, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_preparar_certificacion()
RETURNS TRIGGER AS $$
DECLARE
    v_codigo TEXT;
BEGIN
    IF NEW.folio_unico IS NULL OR BTRIM(NEW.folio_unico) = '' THEN
        NEW.folio_unico := fn_generar_folio_certificacion();
    END IF;

    IF NEW.contenido_json IS NULL THEN
        RAISE EXCEPTION 'La certificación debe tener contenido_json para calcular el hash.';
    END IF;

    NEW.hash_seguridad := fn_generar_hash_certificacion(NEW.contenido_json);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_crear_verificacion_certificacion()
RETURNS TRIGGER AS $$
DECLARE
    v_codigo TEXT;
BEGIN
    v_codigo := 'VER-' || NEW.folio_unico || '-' || SUBSTRING(NEW.hash_seguridad FROM 1 FOR 10);

    INSERT INTO verificacion_externa (
        id_certificacion,
        codigo_verificacion,
        url_verificacion,
        qr_code
    )
    VALUES (
        NEW.id_certificacion,
        v_codigo,
        '/verificar-certificacion/' || v_codigo,
        v_codigo
    )
    ON CONFLICT (codigo_verificacion) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_anular_certificacion(
    p_id_certificacion INTEGER,
    p_motivo TEXT,
    p_id_usuario_anulacion INTEGER,
    p_id_certificacion_sustituta INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    IF p_motivo IS NULL OR BTRIM(p_motivo) = '' THEN
        RAISE EXCEPTION 'Debe indicar una justificación obligatoria para anular la certificación.';
    END IF;

    -- Habilitar temporalmente la modificación controlada
    PERFORM set_config('app.permite_anulacion', 'true', TRUE);

    UPDATE certificacion_emitida
    SET estado = 'Anulada',
        motivo_anulacion = p_motivo
    WHERE id_certificacion = p_id_certificacion
      AND estado <> 'Anulada';

    IF NOT FOUND THEN
        PERFORM set_config('app.permite_anulacion', 'false', TRUE);
        RAISE EXCEPTION 'La certificación no existe o ya estaba anulada.';
    END IF;

    INSERT INTO anulacion_certificacion (
        id_certificacion,
        motivo,
        id_usuario_anulacion,
        justificacion_detalle,
        id_certificacion_sustituta
    )
    VALUES (
        p_id_certificacion,
        p_motivo,
        p_id_usuario_anulacion,
        p_motivo,
        p_id_certificacion_sustituta
    );

    UPDATE verificacion_externa
    SET activo = FALSE
    WHERE id_certificacion = p_id_certificacion;

    -- Revocar el permiso temporal
    PERFORM set_config('app.permite_anulacion', 'false', TRUE);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_registrar_verificacion_externa(
    p_codigo_verificacion VARCHAR
)
RETURNS TABLE (
    folio_unico VARCHAR,
    estado VARCHAR,
    hash_seguridad VARCHAR,
    fecha_emision DATE,
    nombre_asambleista VARCHAR,
    mensaje_validacion TEXT
) AS $$
BEGIN
    UPDATE verificacion_externa
    SET veces_verificado = veces_verificado + 1,
        ultima_verificacion = CURRENT_TIMESTAMP
    WHERE codigo_verificacion = p_codigo_verificacion;

    RETURN QUERY
    SELECT
        ce.folio_unico,
        ce.estado,
        ce.hash_seguridad,
        ce.fecha_emision,
        a.nombre,
        CASE
            WHEN ce.estado = 'Activa' AND ve.activo = TRUE
                THEN 'Documento auténtico y vigente'
            WHEN ce.estado = 'Anulada'
                THEN 'Documento inválido: certificación anulada'
            ELSE 'Documento no vigente o suspendido'
        END AS mensaje_validacion
    FROM verificacion_externa ve
    JOIN certificacion_emitida ce
        ON ve.id_certificacion = ce.id_certificacion
    JOIN asambleista a
        ON ce.id_asambleista = a.id_asambleista
    WHERE ve.codigo_verificacion = p_codigo_verificacion;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_preparar_certificacion
BEFORE INSERT ON certificacion_emitida
FOR EACH ROW
EXECUTE FUNCTION fn_preparar_certificacion();

CREATE TRIGGER tg_crear_verificacion_certificacion
AFTER INSERT ON certificacion_emitida
FOR EACH ROW
EXECUTE FUNCTION fn_crear_verificacion_certificacion();

CREATE OR REPLACE FUNCTION fn_no_repudio_certificacion()
RETURNS TRIGGER AS $$
DECLARE
    v_permite_anulacion TEXT;
BEGIN
    BEGIN
        v_permite_anulacion := current_setting('app.permite_anulacion', TRUE);
    EXCEPTION WHEN OTHERS THEN
        v_permite_anulacion := '';
    END;

    IF v_permite_anulacion = 'true' THEN
        RETURN OLD;
    END IF;

    RAISE EXCEPTION
        'Operación bloqueada: las certificaciones emitidas son inmutables. Folio: %. Para invalidar use fn_anular_certificacion().',
        OLD.folio_unico;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_no_repudio_cert
BEFORE UPDATE OR DELETE ON certificacion_emitida
FOR EACH ROW
EXECUTE FUNCTION fn_no_repudio_certificacion();

-- =====================================================
-- 16. VISTAS
-- =====================================================

CREATE OR REPLACE VIEW v_proponentes_propuesta AS
SELECT
    p.id_propuesta,
    p.numero_propuesta,
    p.titulo AS titulo_propuesta,
    a.id_asambleista,
    a.cedula,
    a.nombre AS nombre_asambleista,
    pp.rol_proponente
FROM proponente_propuesta pp
JOIN propuesta p ON pp.id_propuesta = p.id_propuesta
JOIN asambleista a ON pp.id_asambleista = a.id_asambleista;

CREATE OR REPLACE VIEW v_integrantes_comision AS
SELECT
    ic.id_integrante_comision,
    c.id_comision,
    c.nombre_comision,
    a.id_asambleista,
    a.cedula,
    a.nombre AS nombre_asambleista,
    rc.nombre_rol,
    ic.fecha_ingreso_nombramiento,
    ic.fecha_fin_nombramiento,
    ic.estado
FROM integrante_comision ic
JOIN comision c ON ic.id_comision = c.id_comision
JOIN asambleista a ON ic.id_asambleista = a.id_asambleista
JOIN catalogo_rol_comision rc ON ic.id_rol_comision = rc.id_rol_comision;

CREATE OR REPLACE VIEW v_asistencia_comision AS
SELECT
    asc2.id_asistencia_comision,
    c.id_comision,
    c.nombre_comision,
    sc.id_sesion_comision,
    sc.fecha_hora,
    a.id_asambleista,
    a.cedula,
    a.nombre AS nombre_asambleista,
    ea.nombre AS estado_asistencia
FROM asistencia_sesion_comision asc2
JOIN sesion_comision sc ON asc2.id_sesion_comision = sc.id_sesion_comision
JOIN comision c ON asc2.id_comision = c.id_comision
JOIN asambleista a ON asc2.id_asambleista = a.id_asambleista
JOIN catalogo_estado_asistencia ea ON asc2.id_estado_asistencia = ea.id_estado_asistencia;

CREATE OR REPLACE VIEW v_informes_comision_certificacion AS
SELECT
    i.id_informe,
    c.id_comision,
    c.nombre_comision,
    p.id_propuesta,
    p.numero_propuesta,
    p.titulo AS titulo_propuesta,
    i.titulo AS titulo_informe,
    i.recomendacion,
    i.fecha_presentacion
FROM informe_directorio i
JOIN comision c ON i.id_comision = c.id_comision
JOIN propuesta p ON i.id_propuesta = p.id_propuesta;

CREATE OR REPLACE VIEW v_memoria_votacion_sesion AS
SELECT
    v.id_votacion,
    s.id_sesion,
    s.numero_sesion,
    s.fecha,
    p.id_propuesta,
    p.numero_propuesta,
    p.titulo AS titulo_propuesta,
    v.numero_votacion,
    v.tipo_votacion,
    v.votos_favor,
    v.votos_contra,
    v.votos_abstencion,
    v.total_votantes,
    v.resultado,
    v.estado_acuerdo,
    v.fecha_firma_acuerdo
FROM votacion v
JOIN sesion s ON v.id_sesion = s.id_sesion
LEFT JOIN propuesta p ON v.id_propuesta = p.id_propuesta;

CREATE OR REPLACE VIEW v_estado_quorum_sesion AS
SELECT
    s.id_sesion,
    s.numero_sesion,
    s.fecha,
    cts.nombre AS tipo_sesion,
    cts.quorum_porcentaje,
    COALESCE(s.total_asambleistas, fn_total_asambleistas_activos(s.fecha)) AS total_asambleistas,
    fn_asistentes_para_quorum(s.id_sesion) AS presentes_para_quorum,
    fn_quorum_requerido(s.id_sesion) AS quorum_requerido,
    CASE
        WHEN fn_validar_quorum(s.id_sesion) THEN 'Quórum válido'
        ELSE 'Quórum insuficiente'
    END AS estado_quorum
FROM sesion s
INNER JOIN catalogo_tipo_sesion cts
    ON s.id_tipo_sesion = cts.id_tipo_sesion;

CREATE OR REPLACE VIEW v_resultado_votacion_detalle AS
SELECT
    rv.id_resultado_votacion,
    v.id_votacion,
    s.numero_sesion,
    s.fecha,
    p.numero_propuesta,
    p.titulo AS titulo_propuesta,
    cm.nombre AS tipo_mayoria,
    cm.porcentaje_requerido,
    ctv.nombre AS tipo_votacion,
    rv.total_presentes,
    rv.total_votos,
    rv.votos_favor,
    rv.votos_contra,
    rv.abstenciones,
    rv.porcentaje_aprobacion,
    rv.resultado,
    rv.fecha_apertura,
    rv.fecha_cierre
FROM resultado_votacion rv
JOIN votacion v ON rv.id_votacion = v.id_votacion
JOIN sesion s ON v.id_sesion = s.id_sesion
LEFT JOIN propuesta p ON v.id_propuesta = p.id_propuesta
JOIN catalogo_tipo_mayoria_requerida cm
    ON rv.id_tipo_mayoria_requerida = cm.id_tipo_mayoria_requerida
JOIN catalogo_tipo_votacion ctv
    ON rv.id_tipo_votacion = ctv.id_tipo_votacion;

CREATE OR REPLACE VIEW v_votos_nominales AS
SELECT
    va.id_voto_asambleista,
    va.id_votacion,
    s.numero_sesion,
    a.id_asambleista,
    a.cedula,
    a.nombre AS nombre_asambleista,
    tv.nombre AS voto,
    va.fecha_voto
FROM voto_asambleista va
JOIN votacion v ON va.id_votacion = v.id_votacion
JOIN sesion s ON v.id_sesion = s.id_sesion
JOIN asambleista a ON va.id_asambleista = a.id_asambleista
JOIN catalogo_tipo_voto tv ON va.id_tipo_voto = tv.id_tipo_voto
WHERE v.tipo_votacion = 'Publica';

CREATE OR REPLACE VIEW v_leyendas_propuesta AS
SELECT
    p.id_propuesta,
    p.numero_propuesta,
    p.titulo AS titulo_propuesta,
    o.nombre AS origen_propuesta,
    e.nombre AS etapa_propuesta,
    ep.nombre AS estado_propuesta,
    l.codigo,
    l.titulo AS titulo_leyenda,
    l.contenido,
    pl.orden_aparicion
FROM propuesta_leyenda pl
JOIN propuesta p ON pl.id_propuesta = p.id_propuesta
JOIN leyenda_nota_condicional l ON pl.id_leyenda = l.id_leyenda
LEFT JOIN catalogo_origen_propuesta o ON p.id_origen_propuesta = o.id_origen_propuesta
LEFT JOIN catalogo_etapa_propuesta e ON p.id_etapa_propuesta = e.id_etapa_propuesta
LEFT JOIN catalogo_estado_propuesta ep ON p.id_estado_propuesta = ep.id_estado_propuesta;

CREATE OR REPLACE VIEW v_compilador_normativo_vigente AS
SELECT
    r.id_reglamento,
    r.nombre_normativa,
    r.sigla,
    en.id_elemento,
    en.id_elemento_padre,
    nr.nombre AS nivel,
    en.numero_etiqueta,
    en.contenido_texto,
    en.orden,
    en.fecha_inicio_vigencia,
    en.fecha_fin_vigencia,
    ev.nombre AS estado_vigencia
FROM elemento_normativo en
JOIN reglamento r ON en.id_reglamento = r.id_reglamento
JOIN catalogo_nivel_reglamento nr ON en.id_nivel_reglamento = nr.id_nivel_reglamento
JOIN catalogo_estado_vigencia ev ON en.id_estado_vigencia = ev.id_estado_vigencia
WHERE en.fecha_fin_vigencia IS NULL
  AND ev.nombre = 'Vigente';

CREATE OR REPLACE VIEW v_arbol_normativo AS
WITH RECURSIVE arbol AS (
    SELECT
        en.id_elemento,
        en.id_reglamento,
        en.id_elemento_padre,
        en.numero_etiqueta,
        en.contenido_texto,
        en.orden,
        1 AS profundidad,
        en.numero_etiqueta::TEXT AS ruta
    FROM elemento_normativo en
    WHERE en.id_elemento_padre IS NULL

    UNION ALL

    SELECT
        hijo.id_elemento,
        hijo.id_reglamento,
        hijo.id_elemento_padre,
        hijo.numero_etiqueta,
        hijo.contenido_texto,
        hijo.orden,
        padre.profundidad + 1,
        padre.ruta || ' > ' || hijo.numero_etiqueta
    FROM elemento_normativo hijo
    JOIN arbol padre ON hijo.id_elemento_padre = padre.id_elemento
)
SELECT
    a.*,
    r.nombre_normativa
FROM arbol a
JOIN reglamento r ON a.id_reglamento = r.id_reglamento;

CREATE OR REPLACE VIEW v_historial_vigencia_elemento AS
SELECT
    e.id_elemento,
    r.id_reglamento,
    r.nombre_normativa,
    r.sigla,
    e.id_elemento_padre,
    cnr.nombre AS nivel,
    e.numero_etiqueta,
    e.contenido_texto,
    e.orden,
    e.fecha_inicio_vigencia,
    e.fecha_fin_vigencia,
    cev.nombre AS estado_vigencia,
    p.numero_propuesta AS propuesta_origen,
    p.titulo AS titulo_propuesta,
    v.numero_votacion AS votacion_origen,
    v.resultado AS resultado_votacion,
    e.observacion_vigencia
FROM elemento_normativo e
JOIN reglamento r
    ON e.id_reglamento = r.id_reglamento
JOIN catalogo_nivel_reglamento cnr
    ON e.id_nivel_reglamento = cnr.id_nivel_reglamento
JOIN catalogo_estado_vigencia cev
    ON e.id_estado_vigencia = cev.id_estado_vigencia
LEFT JOIN propuesta p
    ON e.id_propuesta_origen = p.id_propuesta
LEFT JOIN votacion v
    ON e.id_votacion_origen = v.id_votacion;

CREATE OR REPLACE VIEW v_trazabilidad_normativa AS
SELECT
    e.id_elemento,
    r.nombre_normativa,
    e.numero_etiqueta,
    e.contenido_texto,
    e.fecha_inicio_vigencia,
    e.fecha_fin_vigencia,
    cev.nombre AS estado_vigencia,
    p.numero_propuesta,
    p.titulo AS titulo_propuesta,
    p.numero_resolucion,
    rv.resultado AS resultado_votacion,
    rv.porcentaje_aprobacion,
    s.numero_sesion,
    s.fecha AS fecha_sesion
FROM elemento_normativo e
JOIN reglamento r
    ON e.id_reglamento = r.id_reglamento
JOIN catalogo_estado_vigencia cev
    ON e.id_estado_vigencia = cev.id_estado_vigencia
LEFT JOIN propuesta p
    ON e.id_propuesta_origen = p.id_propuesta
LEFT JOIN votacion v
    ON e.id_votacion_origen = v.id_votacion
LEFT JOIN resultado_votacion rv
    ON v.id_votacion = rv.id_votacion
LEFT JOIN sesion s
    ON v.id_sesion = s.id_sesion;

CREATE OR REPLACE VIEW v_compilador_historico_fecha AS
SELECT
    e.id_elemento,
    r.id_reglamento,
    r.nombre_normativa,
    r.sigla,
    e.id_elemento_padre,
    cnr.nombre AS nivel,
    e.numero_etiqueta,
    e.contenido_texto,
    e.orden,
    e.fecha_inicio_vigencia,
    e.fecha_fin_vigencia,
    cev.nombre AS estado_vigencia,
    p.numero_propuesta AS propuesta_origen,
    v.numero_votacion AS votacion_origen
FROM elemento_normativo e
JOIN reglamento r
    ON e.id_reglamento = r.id_reglamento
JOIN catalogo_nivel_reglamento cnr
    ON e.id_nivel_reglamento = cnr.id_nivel_reglamento
JOIN catalogo_estado_vigencia cev
    ON e.id_estado_vigencia = cev.id_estado_vigencia
LEFT JOIN propuesta p
    ON e.id_propuesta_origen = p.id_propuesta
LEFT JOIN votacion v
    ON e.id_votacion_origen = v.id_votacion;

CREATE OR REPLACE VIEW v_certificacion_datos_consolidados AS
SELECT
    a.id_asambleista,
    a.cedula,
    a.nombre AS nombre_asambleista,
    a.correo_institucional,

    COUNT(DISTINCT n.id_nombramiento) AS total_nombramientos,
    MIN(n.fecha_inicio) AS primer_periodo_inicio,
    MAX(COALESCE(n.fecha_fin, CURRENT_DATE)) AS ultimo_periodo_fin,

    COUNT(DISTINCT asp.id_asistencia) AS total_asistencias_plenarias,
    COUNT(DISTINCT asc2.id_asistencia_comision) AS total_asistencias_comision,

    COUNT(DISTINCT pp.id_propuesta) AS total_propuestas_como_proponente,
    COUNT(DISTINCT ic.id_comision) AS total_comisiones_integradas,
    COUNT(DISTINCT va.id_voto_asambleista) AS total_votos_registrados,

    JSONB_AGG(DISTINCT JSONB_BUILD_OBJECT(
        'id_nombramiento', n.id_nombramiento,
        'sector', cs.nombre,
        'puesto', cp.nombre_puesto,
        'fecha_inicio', n.fecha_inicio,
        'fecha_fin', n.fecha_fin,
        'estado', n.estado
    )) FILTER (WHERE n.id_nombramiento IS NOT NULL) AS nombramientos,

    JSONB_AGG(DISTINCT JSONB_BUILD_OBJECT(
        'numero_propuesta', p.numero_propuesta,
        'titulo', p.titulo,
        'fecha_presentacion', p.fecha_presentacion
    )) FILTER (WHERE p.id_propuesta IS NOT NULL) AS propuestas,

    JSONB_AGG(DISTINCT JSONB_BUILD_OBJECT(
        'comision', c.nombre_comision,
        'rol', rc.nombre_rol,
        'fecha_ingreso', ic.fecha_ingreso_nombramiento,
        'fecha_fin', ic.fecha_fin_nombramiento
    )) FILTER (WHERE c.id_comision IS NOT NULL) AS comisiones

FROM asambleista a
LEFT JOIN nombramiento n
    ON a.id_asambleista = n.id_asambleista
LEFT JOIN catalogo_sector cs
    ON n.id_sector = cs.id_sector
LEFT JOIN catalogo_puestos cp
    ON n.id_puesto = cp.id_puesto
LEFT JOIN asistencia_sesion_plenaria asp
    ON a.id_asambleista = asp.id_asambleista
LEFT JOIN asistencia_sesion_comision asc2
    ON a.id_asambleista = asc2.id_asambleista
LEFT JOIN proponente_propuesta pp
    ON a.id_asambleista = pp.id_asambleista
LEFT JOIN propuesta p
    ON pp.id_propuesta = p.id_propuesta
LEFT JOIN integrante_comision ic
    ON a.id_asambleista = ic.id_asambleista
LEFT JOIN comision c
    ON ic.id_comision = c.id_comision
LEFT JOIN catalogo_rol_comision rc
    ON ic.id_rol_comision = rc.id_rol_comision
LEFT JOIN voto_asambleista va
    ON a.id_asambleista = va.id_asambleista
GROUP BY
    a.id_asambleista,
    a.cedula,
    a.nombre,
    a.correo_institucional;

CREATE OR REPLACE VIEW v_verificacion_certificacion AS
SELECT
    ce.id_certificacion,
    ce.folio_unico,
    ce.hash_seguridad,
    ce.estado,
    ce.fecha_emision,
    a.cedula,
    a.nombre AS nombre_asambleista,
    ce.url_pdf,
    ve.codigo_verificacion,
    ve.url_verificacion,
    ve.activo AS verificacion_activa,
    ve.veces_verificado,
    ve.ultima_verificacion,
    CASE
        WHEN ce.estado = 'Activa' AND ve.activo = TRUE THEN 'Válida'
        WHEN ce.estado = 'Anulada' THEN 'Anulada'
        ELSE 'No vigente'
    END AS estado_publico
FROM certificacion_emitida ce
JOIN asambleista a
    ON ce.id_asambleista = a.id_asambleista
LEFT JOIN verificacion_externa ve
    ON ce.id_certificacion = ve.id_certificacion;

CREATE OR REPLACE VIEW v_reporte_certificaciones_mensual AS
SELECT
    EXTRACT(YEAR FROM fecha_emision)::INTEGER AS anio,
    EXTRACT(MONTH FROM fecha_emision)::INTEGER AS mes,
    estado,
    COUNT(*) AS total_certificaciones
FROM certificacion_emitida
GROUP BY
    EXTRACT(YEAR FROM fecha_emision),
    EXTRACT(MONTH FROM fecha_emision),
    estado;

-- =====================================================
-- 17. DATOS INICIALES
-- =====================================================

INSERT INTO catalogo_sector (id_sector, nombre, descripcion) VALUES
    (1, 'Docente', 'Representante del sector docente'),
    (2, 'Administrativo', 'Personal administrativo'),
    (3, 'Estudiantil', 'Representación estudiantil');

INSERT INTO catalogo_puestos (id_puesto, nombre_puesto, descripcion) VALUES
    (1, 'Propietario', 'Representante propietario'),
    (2, 'Suplente', 'Representante suplente'),
    (3, 'Presidente', 'Presidente del directorio');

INSERT INTO catalogo_nivel_reglamento (id_nivel_reglamento, nombre, orden) VALUES
    (1, 'Título', 1),
    (2, 'Capítulo', 2),
    (3, 'Artículo', 3),
    (4, 'Inciso', 4),
    (5, 'Sub-inciso', 5);

INSERT INTO catalogo_estado_vigencia (id_estado_vigencia, nombre, descripcion) VALUES
    (1, 'Vigente', 'Versión activa actualmente'),
    (2, 'Histórico', 'Versión anterior'),
    (3, 'Derogado', 'Versión eliminada por reforma');

INSERT INTO catalogo_tipo_reforma (id_tipo_reforma, nombre, descripcion) VALUES
    (1, 'Modificación', 'Cambio de texto en un elemento normativo'),
    (2, 'Derogación', 'Eliminación de una norma vigente'),
    (3, 'Adición', 'Agrega nuevo contenido normativo');

INSERT INTO sys_rol (id_rol, nombre_rol, descripcion) VALUES
    (1, 'Administrador', 'Control total del sistema'),
    (2, 'Secretaria_AIR', 'Gestión de normativa y certificaciones'),
    (3, 'Directorio', 'Planificación de sesiones'),
    (4, 'Asambleísta', 'Consulta y creación de mociones'),
    (5, 'Consulta', 'Solo lectura');

INSERT INTO sys_permiso (id_permiso, nombre_permiso, descripcion) VALUES
    (1, 'crear_mocion', 'Permite crear mociones'),
    (2, 'certificar', 'Permite emitir certificaciones'),
    (3, 'planificar', 'Permite organizar agenda'),
    (4, 'editar_normativa', 'Permite crear y editar normativa'),
    (5, 'consultar_normativa', 'Permite consultar normativa');

INSERT INTO sys_usuario (id_usuario, username, password_hash, email, activo) VALUES
    (1, 'admin',            '$2b$10$rWP2zXw8iKjddU.PiKBsIul9ELjT0fngspOOOr.J9nu3aO.GOVOfi', 'admin@air.go.cr', TRUE),
    (2, 'secretaria',       '$2b$10$UX9sFXgY85ICf5f095TSQOV5VvASwRlD47jO2fBDh4SLYmYYI/IBm', 'secretaria@air.go.cr', TRUE),
    (3, 'asambleista_user', '$2b$10$Xn2N1wI6cpSddDVpW/9EAOVayzra8renAPoWJMarkSfTzihUM84km', 'asambleista@air.go.cr', TRUE),
    (4, 'directorio01',     '$2b$10$cFyI1ebYFJEzypQOdKj4Te4Dj7QogZ3BjxdIEH8vH/6.fz.IGMYRm', 'directorio@air.go.cr', TRUE),
    (5, 'consulta01',       '$2b$10$Vco/qYEuymdbOLrd6BFraO.qYtCyl4hp8QqBwzzT8Jx64KC2sx.3m', 'consulta@air.go.cr', TRUE);

INSERT INTO sys_usuario_rol (id_usuario, id_rol) VALUES
(1, 1),
(2, 2),
(3, 4),
(4, 3),
(5, 5);

INSERT INTO sys_rol_permiso (id_rol, id_permiso) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
(2, 2), (2, 4), (2, 5),
(3, 3), (3, 5),
(4, 1), (4, 5),
(5, 5);

INSERT INTO asambleista (id_asambleista, cedula, nombre, correo_institucional) VALUES
    (1, '1-2345-6789', 'Ana Rodríguez Mora', 'arodriguez@tec.ac.cr'),
    (2, '2-3456-7890', 'Carlos Jiménez Solano', 'cjimenez@tec.ac.cr');

UPDATE asambleista
SET nombre = 'Ana María Rodríguez Mora'
WHERE cedula = '1-2345-6789';

INSERT INTO reglamento (id_reglamento, nombre_normativa, sigla, descripcion) VALUES
    (1, 'Estatuto Orgánico del TEC', 'EO', 'Normativa principal institucional'),
    (2, 'Reglamento de Enseñanza-Aprendizaje', 'REA', 'Reglamento académico');

INSERT INTO elemento_normativo
    (id_elemento, id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta, contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
VALUES
    (1, 1, NULL, 1, 'I', 'Disposiciones Preliminares', 1, '2024-01-01', 1, 1),
    (2, 1, 1, 2, '1', 'De la Naturaleza Jurídica', 1, '2024-01-01', 1, 1),
    (3, 1, 2, 3, '1.1', 'Texto original del artículo 1.', 1, '2024-01-01', 1, 1);

INSERT INTO nombramiento
    (id_nombramiento, id_asambleista, id_sector, id_puesto, resolucion_id, fecha_inicio, fecha_fin, estado, id_usuario_registro, observaciones)
VALUES
    (1, 1, 1, 1, NULL, '2024-01-15', NULL, 'Activo', 1, 'Nombramiento inicial'),
    (2, 2, 2, 2, NULL, '2024-02-01', '2024-12-31', 'Finalizado', 1, 'Nombramiento con fecha de fin');

-- Al insertar una nueva versión vigente del artículo 1.1, el trigger convierte automáticamente la versión anterior en Histórica:
INSERT INTO elemento_normativo
    (id_elemento, id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta, contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
VALUES
    (4, 1, 2, 3, '1.1', 'Texto reformado del artículo 1.', 1, '2025-01-01', 1, 1),
    (5, 1, 3, 4, 'a)', 'Este es un inciso de ejemplo dentro del artículo 1.1', 1, '2024-01-01', 1, 1);

INSERT INTO reforma_aplicada
    (id_reforma, id_resolucion, id_elemento_normativo, texto_anterior, texto_nuevo, fecha_inicio_vigencia, id_tipo_reforma, id_usuario_registro)
VALUES
    (1, NULL, 3, 'Texto original del artículo 1.', 'Texto reformado del artículo 1.', '2025-01-01', 1, 1);

-- Sprint 3:

INSERT INTO catalogo_estado_propuesta
    (id_estado_propuesta, nombre, descripcion)
VALUES
    (1, 'Recibida', 'Propuesta recibida por la Secretaría de la AIR'),
    (2, 'En análisis', 'Propuesta asignada a comisión para análisis técnico'),
    (3, 'Dictaminada', 'Propuesta con informe de comisión'),
    (4, 'Aprobada', 'Propuesta aprobada'),
    (5, 'Rechazada', 'Propuesta rechazada')
ON CONFLICT (id_estado_propuesta) DO NOTHING;

INSERT INTO catalogo_tipo_propuesta
    (id_tipo_propuesta, nombre, descripcion, leyenda_legal)
VALUES
    (1, 'Etapa de Procedencia - Consejo Institucional', 'Propuesta enviada por el Consejo Institucional', 'La Secretaría de la AIR no dispone de registros de asistencia para esta etapa de procedencia.'),
    (2, 'Etapa de Procedencia - 10% Asamblea', 'Propuesta presentada por al menos el 10% de la Asamblea', 'La propuesta fue presentada por el porcentaje requerido de miembros de la Asamblea.'),
    (3, 'Propuesta conciliada', 'Propuesta construida por comisión o grupo de análisis', 'La propuesta conciliada registra proponentes e integrantes participantes.')
ON CONFLICT (id_tipo_propuesta) DO NOTHING;

INSERT INTO catalogo_tipo_comision
    (id_tipo_comision, nombre, descripcion)
VALUES
    (1, 'Comisión de análisis', 'Comisión encargada del estudio técnico de propuestas'),
    (2, 'Comisión especial', 'Comisión temporal creada para un asunto específico')
ON CONFLICT (id_tipo_comision) DO NOTHING;

INSERT INTO catalogo_rol_comision
    (id_rol_comision, nombre_rol, descripcion)
VALUES
    (1, 'Coordinador', 'Coordina el trabajo de la comisión'),
    (2, 'Secretario', 'Registra acuerdos y seguimiento'),
    (3, 'Integrante', 'Participa en el análisis técnico')
ON CONFLICT (id_rol_comision) DO NOTHING;

INSERT INTO catalogo_tipo_tramite
    (id_tipo_tramite, nombre, descripcion)
VALUES
    (1, 'Lectura de acta', 'Revisión y aprobación del acta anterior'),
    (2, 'Análisis de propuesta', 'Discusión técnica de una propuesta asignada'),
    (3, 'Audiencia', 'Recepción de expertos, proponentes o sectores afectados'),
    (4, 'Varios', 'Otros asuntos de la comisión')
ON CONFLICT (id_tipo_tramite) DO NOTHING;

INSERT INTO catalogo_estado_asistencia
    (id_estado_asistencia, nombre, descripcion)
VALUES
    (1, 'Presente',    'Asistió a la sesión'),
    (2, 'Ausente',     'No asistió a la sesión'),
    (3, 'Justificado', 'Ausencia justificada'),
    (4, 'Retardo',     'Llegó tarde pero participa en la sesión')
ON CONFLICT (id_estado_asistencia) DO NOTHING;

INSERT INTO catalogo_tipo_sesion
    (id_tipo_sesion, nombre, descripcion, quorum_porcentaje, requiere_mayoria_calificada)
VALUES
    (1, 'Ordinaria',      'Sesión regular programada en el calendario',      50.00, FALSE),
    (2, 'Extraordinaria', 'Sesión convocada fuera del calendario ordinario',  66.00, TRUE),
    (3, 'Solemne',        'Sesión protocolaria o conmemorativa',              33.00, FALSE)
ON CONFLICT (id_tipo_sesion) DO NOTHING;

INSERT INTO catalogo_tipo_modalidad
    (id_tipo_modalidad, nombre, descripcion)
VALUES
    (1, 'Presencial', 'Sesión realizada en el recinto de la AIR'),
    (2, 'Virtual',    'Sesión realizada por videoconferencia'),
    (3, 'Mixta',      'Combinación de presencial y virtual')
ON CONFLICT (id_tipo_modalidad) DO NOTHING;

INSERT INTO catalogo_tipo_mayoria_requerida
    (id_tipo_mayoria_requerida, nombre, porcentaje_requerido, descripcion)
VALUES
    (1, 'Simple', 50.00, 'Mayoría simple: más votos a favor que en contra'),
    (2, 'Calificada', 66.67, 'Mayoría calificada: al menos dos tercios de los presentes')
ON CONFLICT (id_tipo_mayoria_requerida) DO NOTHING;

INSERT INTO catalogo_tipo_votacion
    (id_tipo_votacion, nombre, descripcion)
VALUES
    (1, 'Publica', 'Votación nominal visible'),
    (2, 'Secreta', 'Votación anónima para reportes públicos')
ON CONFLICT (id_tipo_votacion) DO NOTHING;

INSERT INTO catalogo_tipo_voto
    (id_tipo_voto, nombre, descripcion)
VALUES
    (1, 'Favor', 'Voto a favor'),
    (2, 'Contra', 'Voto en contra'),
    (3, 'Abstención', 'Abstención de voto')
ON CONFLICT (id_tipo_voto) DO NOTHING;

INSERT INTO catalogo_etapa_propuesta
    (id_etapa_propuesta, nombre, descripcion, orden)
VALUES
    (1, 'Procedencia', 'Etapa inicial de recepción y validación de procedencia', 1),
    (2, 'Análisis', 'Etapa de análisis técnico o de comisión', 2),
    (3, 'Aprobación', 'Etapa de votación en el pleno', 3),
    (4, 'Implementación', 'Etapa de ejecución o comunicación del acuerdo', 4)
ON CONFLICT (id_etapa_propuesta) DO NOTHING;

INSERT INTO catalogo_origen_propuesta
    (id_origen_propuesta, nombre, codigo, descripcion)
VALUES
    (1, 'Consejo Institucional', 'CI', 'Propuestas originadas por el Consejo Institucional'),
    (2, '10% Asambleístas', '10P', 'Propuestas presentadas por al menos el 10% de los asambleístas'),
    (3, 'Rectoría', 'REC', 'Propuestas originadas por la Rectoría'),
    (4, 'Comisión Especial', 'COM', 'Propuestas originadas por una comisión especial')
ON CONFLICT (id_origen_propuesta) DO NOTHING;

INSERT INTO leyenda_nota_condicional
    (id_leyenda, codigo, titulo, contenido, id_origen_propuesta, orden_por_defecto)
VALUES
    (1, 'LEG-CI-001',
     'Nota de Procedencia - Consejo Institucional',
     'La Secretaría de la AIR no dispone de registros de asistencia detallados para las propuestas en etapa de procedencia originadas por el Consejo Institucional.',
     1,
     1),
    (2, 'LEG-10P-001',
     'Nota de Procedencia - 10% Asambleístas',
     'Conforme al Estatuto Orgánico, las propuestas presentadas por al menos el 10% de los asambleístas se certifican según la recepción formal de la moción y los registros disponibles.',
     2,
     2),
    (3, 'LEG-REC-001',
     'Nota de Recepción General',
     'El presente documento certifica la participación del asambleísta según los registros históricos de la Secretaría de la AIR.',
     NULL,
     99)
ON CONFLICT (id_leyenda) DO NOTHING;

INSERT INTO control_folio (anio, ultimo_numero, prefijo)
VALUES
    (EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, 0, 'DAIR')
ON CONFLICT (anio, prefijo) DO NOTHING;

INSERT INTO reglamento (id_reglamento, nombre_normativa, sigla, descripcion)
VALUES (3, 'Reglamento de Carrera Profesional', 'RCP', 'Normativa de carrera profesional docente')
ON CONFLICT (id_reglamento) DO NOTHING;

INSERT INTO elemento_normativo
    (id_elemento, id_reglamento, id_elemento_padre, id_nivel_reglamento,
     numero_etiqueta, contenido_texto, orden, fecha_inicio_vigencia,
     id_estado_vigencia, id_usuario_registro)
VALUES
    (10, 3, NULL, 1, 'I',   'Disposiciones Generales del RCP', 1, '2024-01-01', 1, 1),
    (11, 3, 10,  2, '1',   'Del Ámbito de Aplicación',        1, '2024-01-01', 1, 1),
    (12, 3, 11,  3, '1.1', 'Todo docente en categoría MT6 que desee ascender deberá acreditar participación activa en la AIR.', 1, '2024-01-01', 1, 1),
    (13, 3, 12,  4, 'a)',  'La participación incluye asistencia a sesiones plenarias y comisiones de análisis.', 1, '2024-01-01', 1, 1)
ON CONFLICT (id_elemento) DO NOTHING;

-- Reiniciar las secuencias después de insertar IDs explícitos:

SELECT setval(pg_get_serial_sequence('catalogo_sector', 'id_sector'), COALESCE(MAX(id_sector), 1)) FROM catalogo_sector;
SELECT setval(pg_get_serial_sequence('catalogo_puestos', 'id_puesto'), COALESCE(MAX(id_puesto), 1)) FROM catalogo_puestos;
SELECT setval(pg_get_serial_sequence('catalogo_nivel_reglamento', 'id_nivel_reglamento'), COALESCE(MAX(id_nivel_reglamento), 1)) FROM catalogo_nivel_reglamento;
SELECT setval(pg_get_serial_sequence('catalogo_estado_vigencia', 'id_estado_vigencia'), COALESCE(MAX(id_estado_vigencia), 1)) FROM catalogo_estado_vigencia;
SELECT setval(pg_get_serial_sequence('catalogo_tipo_reforma', 'id_tipo_reforma'), COALESCE(MAX(id_tipo_reforma), 1)) FROM catalogo_tipo_reforma;
SELECT setval(pg_get_serial_sequence('asambleista', 'id_asambleista'), COALESCE(MAX(id_asambleista), 1)) FROM asambleista;
SELECT setval(pg_get_serial_sequence('sys_usuario', 'id_usuario'), COALESCE(MAX(id_usuario), 1)) FROM sys_usuario;
SELECT setval(pg_get_serial_sequence('sys_rol', 'id_rol'), COALESCE(MAX(id_rol), 1)) FROM sys_rol;
SELECT setval(pg_get_serial_sequence('sys_permiso', 'id_permiso'), COALESCE(MAX(id_permiso), 1)) FROM sys_permiso;
SELECT setval(pg_get_serial_sequence('nombramiento', 'id_nombramiento'), COALESCE(MAX(id_nombramiento), 1)) FROM nombramiento;
SELECT setval(pg_get_serial_sequence('reforma_aplicada', 'id_reforma'), COALESCE(MAX(id_reforma), 1)) FROM reforma_aplicada;

SELECT setval(pg_get_serial_sequence('catalogo_estado_propuesta', 'id_estado_propuesta'), COALESCE(MAX(id_estado_propuesta), 1)) FROM catalogo_estado_propuesta;
SELECT setval(pg_get_serial_sequence('catalogo_tipo_propuesta', 'id_tipo_propuesta'), COALESCE(MAX(id_tipo_propuesta), 1)) FROM catalogo_tipo_propuesta;
SELECT setval(pg_get_serial_sequence('catalogo_tipo_comision', 'id_tipo_comision'), COALESCE(MAX(id_tipo_comision), 1)) FROM catalogo_tipo_comision;
SELECT setval(pg_get_serial_sequence('catalogo_rol_comision', 'id_rol_comision'), COALESCE(MAX(id_rol_comision), 1)) FROM catalogo_rol_comision;
SELECT setval(pg_get_serial_sequence('catalogo_tipo_tramite', 'id_tipo_tramite'), COALESCE(MAX(id_tipo_tramite), 1)) FROM catalogo_tipo_tramite;

SELECT setval(pg_get_serial_sequence('catalogo_tipo_sesion', 'id_tipo_sesion'), COALESCE(MAX(id_tipo_sesion), 1)) FROM catalogo_tipo_sesion;
SELECT setval(pg_get_serial_sequence('catalogo_tipo_modalidad', 'id_tipo_modalidad'), COALESCE(MAX(id_tipo_modalidad), 1)) FROM catalogo_tipo_modalidad;
SELECT setval(pg_get_serial_sequence('catalogo_estado_asistencia', 'id_estado_asistencia'), COALESCE(MAX(id_estado_asistencia), 1)) FROM catalogo_estado_asistencia;

SELECT setval(pg_get_serial_sequence('catalogo_tipo_mayoria_requerida', 'id_tipo_mayoria_requerida'), COALESCE(MAX(id_tipo_mayoria_requerida), 1)) FROM catalogo_tipo_mayoria_requerida;
SELECT setval(pg_get_serial_sequence('catalogo_tipo_votacion', 'id_tipo_votacion'), COALESCE(MAX(id_tipo_votacion), 1)) FROM catalogo_tipo_votacion;
SELECT setval(pg_get_serial_sequence('catalogo_tipo_voto', 'id_tipo_voto'), COALESCE(MAX(id_tipo_voto), 1)) FROM catalogo_tipo_voto;

SELECT setval(pg_get_serial_sequence('catalogo_etapa_propuesta', 'id_etapa_propuesta'), COALESCE(MAX(id_etapa_propuesta), 1)) FROM catalogo_etapa_propuesta;
SELECT setval(pg_get_serial_sequence('catalogo_origen_propuesta', 'id_origen_propuesta'), COALESCE(MAX(id_origen_propuesta), 1)) FROM catalogo_origen_propuesta;
SELECT setval(pg_get_serial_sequence('leyenda_nota_condicional', 'id_leyenda'), COALESCE(MAX(id_leyenda), 1)) FROM leyenda_nota_condicional;

SELECT setval(pg_get_serial_sequence('control_folio', 'id_control'), COALESCE(MAX(id_control), 1)) FROM control_folio;

SELECT setval(pg_get_serial_sequence('reglamento', 'id_reglamento'), COALESCE(MAX(id_reglamento), 1)) FROM reglamento;
SELECT setval(pg_get_serial_sequence('elemento_normativo', 'id_elemento'), COALESCE(MAX(id_elemento), 1)) FROM elemento_normativo;

-- ===============================
-- 18. CONSULTAS DE VERIFICACIÓN
-- ===============================

-- Verificación de catálogos y seguridad.
SELECT * FROM catalogo_sector;
SELECT * FROM catalogo_puestos;
SELECT * FROM sys_usuario;
SELECT * FROM sys_rol;

-- Verificación de asambleístas y bitácora.
SELECT * FROM asambleista;
SELECT * FROM bitacora_asambleistas;

-- Verificación de jerarquía normativa: Título > Capítulo > Artículo.
SELECT
    hijo.id_elemento,
    hijo.numero_etiqueta,
    hijo.contenido_texto,
    padre.numero_etiqueta AS etiqueta_padre,
    padre.contenido_texto AS texto_padre
FROM elemento_normativo hijo
LEFT JOIN elemento_normativo padre
    ON hijo.id_elemento_padre = padre.id_elemento
ORDER BY hijo.id_elemento;

-- Verificación de versión histórica y vigente.
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

-- Verificación de historial de nombramientos.
SELECT * FROM v_historial_nombramientos;

-- Verificación de roles por usuario.
SELECT
    u.username,
    r.nombre_rol
FROM sys_usuario u
INNER JOIN sys_usuario_rol ur ON u.id_usuario = ur.id_usuario
INNER JOIN sys_rol r ON ur.id_rol = r.id_rol
ORDER BY u.id_usuario;

-- Verificación de auditoría.
SELECT * FROM sys_log_auditoria ORDER BY id_log;

