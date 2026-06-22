// src/models/Votacion.js
// Issue #12 - Motor de Votaciones
// Depende de: sesion, votacion, resultado_votacion, catalogo_tipo_mayoria_requerida

const db = require('../config/db');

class Votacion {
    
    // =====================================================
    // 1. CRUD BÁSICO DE VOTACIONES
    // =====================================================

    // Crear una nueva votación
    static async create(data) {
        const {
            id_sesion,
            id_propuesta,
            id_elemento_normativo,
            numero_votacion,
            tipo_votacion = 'Publica',
            id_tipo_mayoria_requerida,
            id_tipo_votacion
        } = data;

        // Verificar quórum antes de crear la votación
        const quorumValido = await this.validarQuorumSesion(id_sesion);
        if (!quorumValido) {
            throw new Error('No se puede iniciar la votación: quórum insuficiente');
        }

        const query = `
            INSERT INTO votacion (
                id_sesion, id_propuesta, id_elemento_normativo,
                numero_votacion, tipo_votacion, resultado
            ) VALUES ($1, $2, $3, $4, $5, 'Pendiente')
            RETURNING id_votacion, id_sesion, resultado
        `;

        const result = await db.query(query, [
            id_sesion,
            id_propuesta || null,
            id_elemento_normativo || null,
            numero_votacion || null,
            tipo_votacion
        ]);

        const id_votacion = result.rows[0].id_votacion;

        // Crear el resultado de votación asociado
        await this.crearResultadoVotacion(id_votacion, id_tipo_mayoria_requerida, id_tipo_votacion);

        return result.rows[0];
    }

    // Crear el registro de resultado de votación
    static async crearResultadoVotacion(id_votacion, id_tipo_mayoria_requerida, id_tipo_votacion) {
        const query = `
            INSERT INTO resultado_votacion (
                id_votacion,
                id_tipo_mayoria_requerida,
                id_tipo_votacion,
                resultado
            ) VALUES ($1, $2, $3, 'Pendiente')
            RETURNING id_resultado_votacion
        `;

        const result = await db.query(query, [
            id_votacion,
            id_tipo_mayoria_requerida,
            id_tipo_votacion
        ]);

        return result.rows[0];
    }

    // Obtener todas las votaciones con filtros
    static async getAll(filters = {}) {
        let query = `
            SELECT 
                v.id_votacion,
                v.id_sesion,
                v.numero_votacion,
                v.tipo_votacion,
                v.votos_favor,
                v.votos_contra,
                v.votos_abstencion,
                v.total_votantes,
                v.resultado,
                v.fecha_registro,
                s.numero_sesion,
                s.fecha AS fecha_sesion,
                rv.id_tipo_mayoria_requerida,
                tm.nombre AS tipo_mayoria,
                tm.porcentaje_requerido,
                tv.nombre AS tipo_votacion_nombre
            FROM votacion v
            INNER JOIN sesion s ON v.id_sesion = s.id_sesion
            LEFT JOIN resultado_votacion rv ON v.id_votacion = rv.id_votacion
            LEFT JOIN catalogo_tipo_mayoria_requerida tm ON rv.id_tipo_mayoria_requerida = tm.id_tipo_mayoria_requerida
            LEFT JOIN catalogo_tipo_votacion tv ON rv.id_tipo_votacion = tv.id_tipo_votacion
            WHERE 1=1
        `;

        const params = [];
        let paramCount = 1;

        if (filters.id_sesion) {
            query += ` AND v.id_sesion = $${paramCount}`;
            params.push(filters.id_sesion);
            paramCount++;
        }

        if (filters.resultado) {
            query += ` AND v.resultado = $${paramCount}`;
            params.push(filters.resultado);
            paramCount++;
        }

        query += ` ORDER BY v.fecha_registro DESC`;

        const result = await db.query(query, params);
        return result.rows;
    }

    // Obtener una votación por ID
    static async getById(id_votacion) {
        const query = `
            SELECT 
                v.*,
                s.numero_sesion,
                s.fecha AS fecha_sesion,
                s.estado AS estado_sesion,
                rv.id_tipo_mayoria_requerida,
                tm.nombre AS tipo_mayoria,
                tm.porcentaje_requerido,
                tv.nombre AS tipo_votacion_nombre,
                rv.total_presentes,
                rv.total_votos,
                rv.porcentaje_aprobacion,
                rv.fecha_apertura,
                rv.fecha_cierre,
                e.numero_etiqueta AS elemento_etiqueta,
                e.contenido_texto AS elemento_texto
            FROM votacion v
            INNER JOIN sesion s ON v.id_sesion = s.id_sesion
            LEFT JOIN resultado_votacion rv ON v.id_votacion = rv.id_votacion
            LEFT JOIN catalogo_tipo_mayoria_requerida tm ON rv.id_tipo_mayoria_requerida = tm.id_tipo_mayoria_requerida
            LEFT JOIN catalogo_tipo_votacion tv ON rv.id_tipo_votacion = tv.id_tipo_votacion
            LEFT JOIN elemento_normativo e ON v.id_elemento_normativo = e.id_elemento
            WHERE v.id_votacion = $1
        `;

        const result = await db.query(query, [id_votacion]);
        return result.rows[0];
    }

    // =====================================================
    // 2. PROCESAMIENTO DE VOTOS
    // =====================================================

    // Registrar un voto (individual)
    static async registrarVoto(id_votacion, tipo_voto) {
        // Validar que la votación esté pendiente
        const votacion = await this.getById(id_votacion);
        if (!votacion) {
            throw new Error('Votación no encontrada');
        }

        if (votacion.resultado !== 'Pendiente') {
            throw new Error(`La votación ya fue ${votacion.resultado.toLowerCase()}`);
        }

        // Actualizar conteos según el tipo de voto
        let campoVoto;
        switch (tipo_voto) {
            case 'Favor':
                campoVoto = 'votos_favor';
                break;
            case 'Contra':
                campoVoto = 'votos_contra';
                break;
            case 'Abstencion':
                campoVoto = 'votos_abstencion';
                break;
            default:
                throw new Error('Tipo de voto inválido. Permitidos: Favor, Contra, Abstencion');
        }

        const query = `
            UPDATE votacion 
            SET 
                ${campoVoto} = ${campoVoto} + 1,
                total_votantes = total_votantes + 1
            WHERE id_votacion = $1
            RETURNING *
        `;

        const result = await db.query(query, [id_votacion]);
        return result.rows[0];
    }

    // Finalizar votación y calcular resultado
    static async finalizarVotacion(id_votacion) {
        // Obtener la votación
        const votacion = await this.getById(id_votacion);
        if (!votacion) {
            throw new Error('Votación no encontrada');
        }

        if (votacion.resultado !== 'Pendiente') {
            throw new Error('La votación ya fue finalizada');
        }

        // Obtener el tipo de mayoría requerida
        const resultadoVotacion = await this.getResultadoVotacion(id_votacion);
        if (!resultadoVotacion) {
            throw new Error('No se encontró el registro de resultado de votación');
        }

        // Calcular resultado usando la función de PostgreSQL
        const queryCalcular = `
            SELECT fn_calcular_resultado_votacion(
                $1, $2, 
                (SELECT nombre FROM catalogo_tipo_mayoria_requerida 
                 WHERE id_tipo_mayoria_requerida = $3)
            ) AS resultado
        `;

        const calcResult = await db.query(queryCalcular, [
            votacion.votos_favor,
            votacion.votos_contra,
            resultadoVotacion.id_tipo_mayoria_requerida
        ]);

        const resultado = calcResult.rows[0].resultado;

        // Actualizar la votación
        const queryUpdate = `
            UPDATE votacion 
            SET resultado = $2
            WHERE id_votacion = $1
            RETURNING *
        `;

        const result = await db.query(queryUpdate, [id_votacion, resultado]);

        // Actualizar resultado_votacion
        const totalVotos = votacion.votos_favor + votacion.votos_contra + votacion.votos_abstencion;
        const porcentajeAprobacion = totalVotos > 0 
            ? ((votacion.votos_favor / totalVotos) * 100) 
            : 0;

        const queryUpdateResultado = `
            UPDATE resultado_votacion 
            SET 
                total_votos = $2,
                votos_favor = $3,
                votos_contra = $4,
                abstenciones = $5,
                porcentaje_aprobacion = $6,
                resultado = $7,
                fecha_cierre = CURRENT_TIMESTAMP
            WHERE id_votacion = $1
            RETURNING *
        `;

        await db.query(queryUpdateResultado, [
            id_votacion,
            totalVotos,
            votacion.votos_favor,
            votacion.votos_contra,
            votacion.votos_abstencion,
            porcentajeAprobacion,
            resultado
        ]);

        return result.rows[0];
    }

    // Obtener el resultado de una votación
    static async getResultadoVotacion(id_votacion) {
        const query = `
            SELECT 
                rv.*,
                tm.nombre AS tipo_mayoria,
                tm.porcentaje_requerido,
                tv.nombre AS tipo_votacion_nombre
            FROM resultado_votacion rv
            LEFT JOIN catalogo_tipo_mayoria_requerida tm ON rv.id_tipo_mayoria_requerida = tm.id_tipo_mayoria_requerida
            LEFT JOIN catalogo_tipo_votacion tv ON rv.id_tipo_votacion = tv.id_tipo_votacion
            WHERE rv.id_votacion = $1
        `;

        const result = await db.query(query, [id_votacion]);
        return result.rows[0];
    }

    // =====================================================
    // 3. VALIDACIONES
    // =====================================================

    // Validar quórum de una sesión
    static async validarQuorumSesion(id_sesion) {
        const query = `SELECT fn_validar_quorum($1) AS quorum_valido`;
        const result = await db.query(query, [id_sesion]);
        return result.rows[0]?.quorum_valido || false;
    }

    // Verificar si se puede votar en una sesión
    static async puedeVotar(id_sesion) {
        // 1. Verificar que la sesión esté en curso
        const sesionQuery = `SELECT estado FROM sesion WHERE id_sesion = $1`;
        const sesionResult = await db.query(sesionQuery, [id_sesion]);
        
        if (!sesionResult.rows[0]) {
            throw new Error('Sesión no encontrada');
        }

        if (sesionResult.rows[0].estado !== 'En Curso') {
            return {
                puede: false,
                motivo: `La sesión está en estado "${sesionResult.rows[0].estado}". Solo se puede votar en sesiones "En Curso".`
            };
        }

        // 2. Verificar quórum
        const quorumValido = await this.validarQuorumSesion(id_sesion);
        if (!quorumValido) {
            return {
                puede: false,
                motivo: 'Quórum insuficiente para iniciar la votación'
            };
        }

        return {
            puede: true,
            motivo: 'OK'
        };
    }

    // =====================================================
    // 4. REPORTES Y ESTADÍSTICAS
    // =====================================================

    // Obtener estadísticas de votaciones por sesión
    static async getEstadisticasBySesion(id_sesion) {
        const query = `
            SELECT 
                COUNT(*) AS total_votaciones,
                COUNT(CASE WHEN resultado = 'Aprobada' THEN 1 END) AS aprobadas,
                COUNT(CASE WHEN resultado = 'Rechazada' THEN 1 END) AS rechazadas,
                COUNT(CASE WHEN resultado = 'Empate' THEN 1 END) AS empates,
                COUNT(CASE WHEN resultado = 'Pendiente' THEN 1 END) AS pendientes,
                SUM(votos_favor) AS total_votos_favor,
                SUM(votos_contra) AS total_votos_contra,
                SUM(votos_abstencion) AS total_abstenciones,
                AVG(votos_favor + votos_contra + votos_abstencion) AS promedio_participacion
            FROM votacion
            WHERE id_sesion = $1
        `;

        const result = await db.query(query, [id_sesion]);
        return result.rows[0];
    }

    // Obtener reporte de votaciones por tipo de mayoría
    static async getReportePorTipoMayoria() {
        const query = `
            SELECT 
                tm.nombre AS tipo_mayoria,
                COUNT(rv.id_resultado_votacion) AS total,
                COUNT(CASE WHEN rv.resultado = 'Aprobada' THEN 1 END) AS aprobadas,
                COUNT(CASE WHEN rv.resultado = 'Rechazada' THEN 1 END) AS rechazadas,
                AVG(rv.porcentaje_aprobacion) AS porcentaje_promedio_aprobacion
            FROM resultado_votacion rv
            INNER JOIN catalogo_tipo_mayoria_requerida tm ON rv.id_tipo_mayoria_requerida = tm.id_tipo_mayoria_requerida
            GROUP BY tm.nombre
            ORDER BY total DESC
        `;

        const result = await db.query(query);
        return result.rows;
    }

    // =====================================================
    // 5. ELIMINAR VOTACIÓN (solo si está pendiente)
    // =====================================================

    static async delete(id_votacion) {
        const votacion = await this.getById(id_votacion);
        if (!votacion) {
            throw new Error('Votación no encontrada');
        }

        if (votacion.resultado !== 'Pendiente') {
            throw new Error(`No se puede eliminar una votación que ya fue ${votacion.resultado.toLowerCase()}`);
        }

        const query = `DELETE FROM votacion WHERE id_votacion = $1 RETURNING id_votacion`;
        const result = await db.query(query, [id_votacion]);
        return result.rows[0];
    }
}

module.exports = Votacion;