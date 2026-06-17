// src/models/Sesion.js
// Issue #11 - Control de Quórum y Sesiones
// Depende de: sesion, asistencia_sesion_plenaria, catalogo_tipo_sesion

const db = require('../config/db');

class Sesion {
    
    // =====================================================
    // 1. CRUD BÁSICO DE SESIONES
    // =====================================================
    
    // Crear una nueva sesión
    static async create(data) {
        const {
            id_tipo_modalidad,
            id_tipo_sesion,
            numero_sesion,
            fecha,
            hora_inicio,
            hora_fin,
            link_acta,
            id_usuario_registro
        } = data;

        const query = `
            INSERT INTO sesion (
                id_tipo_modalidad, id_tipo_sesion, numero_sesion,
                fecha, hora_inicio, hora_fin, link_acta,
                id_usuario_registro, estado
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'Programada')
            RETURNING id_sesion, numero_sesion, fecha, estado
        `;

        const result = await db.query(query, [
            id_tipo_modalidad, id_tipo_sesion, numero_sesion,
            fecha, hora_inicio || null, hora_fin || null, link_acta || null,
            id_usuario_registro
        ]);

        return result.rows[0];
    }

    // Obtener todas las sesiones
    static async getAll(filters = {}) {
        let query = `
            SELECT 
                s.id_sesion,
                s.numero_sesion,
                s.fecha,
                s.hora_inicio,
                s.hora_fin,
                s.estado,
                s.total_asambleistas,
                s.quorum_requerido,
                tm.nombre AS modalidad,
                ts.nombre AS tipo_sesion,
                ts.quorum_porcentaje,
                COALESCE(s.total_asambleistas, fn_total_asambleistas_activos(s.fecha)) AS total_activos,
                fn_asistentes_para_quorum(s.id_sesion) AS presentes,
                fn_quorum_requerido(s.id_sesion) AS quorum_requerido_calculado,
                CASE 
                    WHEN fn_validar_quorum(s.id_sesion) THEN 'Válido'
                    ELSE 'Insuficiente'
                END AS estado_quorum
            FROM sesion s
            INNER JOIN catalogo_tipo_modalidad tm ON s.id_tipo_modalidad = tm.id_tipo_modalidad
            INNER JOIN catalogo_tipo_sesion ts ON s.id_tipo_sesion = ts.id_tipo_sesion
            WHERE 1=1
        `;

        const params = [];
        let paramCount = 1;

        if (filters.estado) {
            query += ` AND s.estado = $${paramCount}`;
            params.push(filters.estado);
            paramCount++;
        }

        if (filters.fecha_desde) {
            query += ` AND s.fecha >= $${paramCount}`;
            params.push(filters.fecha_desde);
            paramCount++;
        }

        if (filters.fecha_hasta) {
            query += ` AND s.fecha <= $${paramCount}`;
            params.push(filters.fecha_hasta);
            paramCount++;
        }

        query += ` ORDER BY s.fecha DESC, s.hora_inicio DESC`;

        const result = await db.query(query, params);
        return result.rows;
    }

    // Obtener una sesión por ID
    static async getById(id_sesion) {
        const query = `
            SELECT 
                s.*,
                tm.nombre AS modalidad,
                ts.nombre AS tipo_sesion,
                ts.quorum_porcentaje,
                ts.requiere_mayoria_calificada,
                fn_total_asambleistas_activos(s.fecha) AS total_activos,
                fn_asistentes_para_quorum($1) AS presentes,
                fn_quorum_requerido($1) AS quorum_requerido_calculado,
                fn_validar_quorum($1) AS quorum_valido
            FROM sesion s
            INNER JOIN catalogo_tipo_modalidad tm ON s.id_tipo_modalidad = tm.id_tipo_modalidad
            INNER JOIN catalogo_tipo_sesion ts ON s.id_tipo_sesion = ts.id_tipo_sesion
            WHERE s.id_sesion = $1
        `;

        const result = await db.query(query, [id_sesion]);
        return result.rows[0];
    }

    // Actualizar una sesión
    static async update(id_sesion, data) {
        const {
            id_tipo_modalidad,
            id_tipo_sesion,
            numero_sesion,
            fecha,
            hora_inicio,
            hora_fin,
            link_acta,
            estado
        } = data;

        const query = `
            UPDATE sesion 
            SET 
                id_tipo_modalidad = COALESCE($2, id_tipo_modalidad),
                id_tipo_sesion = COALESCE($3, id_tipo_sesion),
                numero_sesion = COALESCE($4, numero_sesion),
                fecha = COALESCE($5, fecha),
                hora_inicio = COALESCE($6, hora_inicio),
                hora_fin = COALESCE($7, hora_fin),
                link_acta = COALESCE($8, link_acta),
                estado = COALESCE($9, estado)
            WHERE id_sesion = $1
            RETURNING *
        `;

        const result = await db.query(query, [
            id_sesion,
            id_tipo_modalidad || null,
            id_tipo_sesion || null,
            numero_sesion || null,
            fecha || null,
            hora_inicio || null,
            hora_fin || null,
            link_acta || null,
            estado || null
        ]);

        return result.rows[0];
    }

    // Cambiar estado de una sesión
    static async cambiarEstado(id_sesion, nuevoEstado) {
        const estadosValidos = ['Programada', 'En Curso', 'Finalizada', 'Cancelada'];
        
        if (!estadosValidos.includes(nuevoEstado)) {
            throw new Error(`Estado inválido. Permitidos: ${estadosValidos.join(', ')}`);
        }

        const query = `
            UPDATE sesion 
            SET estado = $2
            WHERE id_sesion = $1
            RETURNING *
        `;

        const result = await db.query(query, [id_sesion, nuevoEstado]);
        return result.rows[0];
    }

    // =====================================================
    // 2. GESTIÓN DE ASISTENCIA
    // =====================================================

    // Registrar asistencia de un asambleísta a una sesión
    static async registrarAsistencia(id_sesion, id_asambleista, id_estado_asistencia, observaciones = null) {
        // Verificar que la sesión existe y está activa
        const sesion = await this.getById(id_sesion);
        if (!sesion) {
            throw new Error('Sesión no encontrada');
        }

        if (sesion.estado === 'Cancelada') {
            throw new Error('No se puede registrar asistencia a una sesión cancelada');
        }

        const query = `
            INSERT INTO asistencia_sesion_plenaria (
                id_asambleista, id_sesion, id_estado_asistencia, observaciones
            ) VALUES ($1, $2, $3, $4)
            ON CONFLICT (id_asambleista, id_sesion) 
            DO UPDATE SET 
                id_estado_asistencia = EXCLUDED.id_estado_asistencia,
                observaciones = EXCLUDED.observaciones,
                hora_registro = CURRENT_TIMESTAMP
            RETURNING *
        `;

        const result = await db.query(query, [
            id_asambleista, id_sesion, id_estado_asistencia, observaciones
        ]);

        return result.rows[0];
    }

    // Obtener lista de asistencia de una sesión
    static async getAsistenciaBySesion(id_sesion) {
        const query = `
            SELECT 
                asp.id_asistencia,
                a.id_asambleista,
                a.nombre,
                a.cedula,
                cea.nombre AS estado_asistencia,
                cea.descripcion AS descripcion_asistencia,
                asp.hora_registro,
                asp.observaciones,
                (SELECT n.id_puesto FROM nombramiento n 
                 WHERE n.id_asambleista = a.id_asambleista 
                   AND n.estado = 'Activo'
                   AND n.fecha_inicio <= CURRENT_DATE
                   AND (n.fecha_fin IS NULL OR n.fecha_fin >= CURRENT_DATE)
                 LIMIT 1) AS id_puesto_actual,
                (SELECT p.nombre_puesto FROM nombramiento n
                 JOIN catalogo_puestos p ON n.id_puesto = p.id_puesto
                 WHERE n.id_asambleista = a.id_asambleista 
                   AND n.estado = 'Activo'
                   AND n.fecha_inicio <= CURRENT_DATE
                   AND (n.fecha_fin IS NULL OR n.fecha_fin >= CURRENT_DATE)
                 LIMIT 1) AS puesto_actual
            FROM asistencia_sesion_plenaria asp
            INNER JOIN asambleista a ON asp.id_asambleista = a.id_asambleista
            INNER JOIN catalogo_estado_asistencia cea ON asp.id_estado_asistencia = cea.id_estado_asistencia
            WHERE asp.id_sesion = $1
            ORDER BY a.nombre ASC
        `;

        const result = await db.query(query, [id_sesion]);
        return result.rows;
    }

    // Obtener resumen de asistencia de una sesión
    static async getResumenAsistencia(id_sesion) {
        const query = `
            SELECT 
                COUNT(*) AS total_registros,
                COUNT(CASE WHEN cea.nombre IN ('Presente', 'Retardo') THEN 1 END) AS presentes,
                COUNT(CASE WHEN cea.nombre = 'Ausente' THEN 1 END) AS ausentes,
                COUNT(CASE WHEN cea.nombre = 'Justificado' THEN 1 END) AS justificados,
                COUNT(CASE WHEN cea.nombre = 'Retardo' THEN 1 END) AS retardos,
                fn_quorum_requerido($1) AS quorum_requerido,
                fn_validar_quorum($1) AS quorum_valido,
                fn_total_asambleistas_activos((SELECT fecha FROM sesion WHERE id_sesion = $1)) AS total_asambleistas_activos
            FROM asistencia_sesion_plenaria asp
            INNER JOIN catalogo_estado_asistencia cea ON asp.id_estado_asistencia = cea.id_estado_asistencia
            WHERE asp.id_sesion = $1
        `;

        const result = await db.query(query, [id_sesion]);
        return result.rows[0];
    }

    // =====================================================
    // 3. FUNCIONES DE QUÓRUM (llamadas desde la BD)
    // =====================================================

    // Verificar si hay quórum en una sesión
    static async validarQuorum(id_sesion) {
        const query = `SELECT fn_validar_quorum($1) AS quorum_valido`;
        const result = await db.query(query, [id_sesion]);
        return result.rows[0]?.quorum_valido || false;
    }

    // Obtener el número de asistentes para quórum
    static async getAsistentesParaQuorum(id_sesion) {
        const query = `SELECT fn_asistentes_para_quorum($1) AS asistentes`;
        const result = await db.query(query, [id_sesion]);
        return parseInt(result.rows[0]?.asistentes) || 0;
    }

    // Obtener el quórum requerido
    static async getQuorumRequerido(id_sesion) {
        const query = `SELECT fn_quorum_requerido($1) AS requerido`;
        const result = await db.query(query, [id_sesion]);
        return parseInt(result.rows[0]?.requerido) || 0;
    }

    // Obtener total de asambleístas activos para una fecha
    static async getTotalAsambleistasActivos(fecha) {
        const query = `SELECT fn_total_asambleistas_activos($1) AS total`;
        const result = await db.query(query, [fecha]);
        return parseInt(result.rows[0]?.total) || 0;
    }

    // =====================================================
    // 4. REPORTES Y VISTAS
    // =====================================================

    // Obtener el estado de quórum de todas las sesiones
    static async getEstadoQuorumAll() {
        const query = `SELECT * FROM v_estado_quorum_sesion ORDER BY fecha DESC`;
        const result = await db.query(query);
        return result.rows;
    }

    // Obtener historial de sesiones de un asambleísta
    static async getHistorialAsistenciaAsambleista(id_asambleista) {
        const query = `
            SELECT 
                s.id_sesion,
                s.numero_sesion,
                s.fecha,
                s.estado AS estado_sesion,
                cea.nombre AS estado_asistencia,
                asp.hora_registro,
                asp.observaciones
            FROM asistencia_sesion_plenaria asp
            INNER JOIN sesion s ON asp.id_sesion = s.id_sesion
            INNER JOIN catalogo_estado_asistencia cea ON asp.id_estado_asistencia = cea.id_estado_asistencia
            WHERE asp.id_asambleista = $1
            ORDER BY s.fecha DESC
        `;

        const result = await db.query(query, [id_asambleista]);
        return result.rows;
    }

    // =====================================================
    // 5. ELIMINAR SESIÓN (solo si está programada)
    // =====================================================

    static async delete(id_sesion) {
        // Verificar que la sesión esté Programada o Cancelada
        const sesion = await this.getById(id_sesion);
        if (!sesion) {
            throw new Error('Sesión no encontrada');
        }

        if (!['Programada', 'Cancelada'].includes(sesion.estado)) {
            throw new Error(`No se puede eliminar una sesión en estado "${sesion.estado}". Solo Programada o Cancelada.`);
        }

        // Eliminar asistencias primero (ON DELETE CASCADE en la BD)
        const query = `DELETE FROM sesion WHERE id_sesion = $1 RETURNING id_sesion`;
        const result = await db.query(query, [id_sesion]);
        return result.rows[0];
    }
}

module.exports = Sesion;