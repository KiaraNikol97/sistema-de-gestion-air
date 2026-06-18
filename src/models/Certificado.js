// src/models/Certificado.js
// Issue #17 - Motor de Certificaciones
// Depende de: certificacion_emitida, solicitud_certificacion, control_folio

const db = require('../config/db');
const CryptoService = require('../services/CryptoService');

class Certificado {
    
    // =====================================================
    // 1. GESTIÓN DE SOLICITUDES
    // =====================================================

    // Crear una nueva solicitud de certificación
    static async crearSolicitud(data) {
        const {
            id_asambleista,
            periodo_desde,
            periodo_hasta,
            observaciones,
            id_usuario_solicitante
        } = data;

        const query = `
            INSERT INTO solicitud_certificacion (
                id_asambleista,
                periodo_desde,
                periodo_hasta,
                observaciones,
                id_usuario_solicitante,
                estado
            ) VALUES ($1, $2, $3, $4, $5, 'Pendiente')
            RETURNING id_solicitud, fecha_solicitud, estado
        `;

        const result = await db.query(query, [
            id_asambleista,
            periodo_desde || null,
            periodo_hasta || null,
            observaciones || null,
            id_usuario_solicitante || null
        ]);

        return result.rows[0];
    }

    // Obtener todas las solicitudes
    static async getSolicitudes(filters = {}) {
        let query = `
            SELECT 
                s.id_solicitud,
                s.id_asambleista,
                a.nombre AS asambleista_nombre,
                a.cedula,
                s.fecha_solicitud,
                s.periodo_desde,
                s.periodo_hasta,
                s.estado,
                s.observaciones,
                s.fecha_respuesta,
                u.username AS solicitante_nombre,
                s.id_certificacion_generada
            FROM solicitud_certificacion s
            INNER JOIN asambleista a ON s.id_asambleista = a.id_asambleista
            LEFT JOIN sys_usuario u ON s.id_usuario_solicitante = u.id_usuario
            WHERE 1=1
        `;

        const params = [];
        let paramCount = 1;

        if (filters.id_asambleista) {
            query += ` AND s.id_asambleista = $${paramCount}`;
            params.push(filters.id_asambleista);
            paramCount++;
        }

        if (filters.estado) {
            query += ` AND s.estado = $${paramCount}`;
            params.push(filters.estado);
            paramCount++;
        }

        query += ` ORDER BY s.fecha_solicitud DESC`;

        const result = await db.query(query, params);
        return result.rows;
    }

    // Obtener una solicitud por ID
    static async getSolicitudById(id_solicitud) {
        const query = `
            SELECT 
                s.*,
                a.nombre AS asambleista_nombre,
                a.cedula,
                u.username AS solicitante_nombre
            FROM solicitud_certificacion s
            INNER JOIN asambleista a ON s.id_asambleista = a.id_asambleista
            LEFT JOIN sys_usuario u ON s.id_usuario_solicitante = u.id_usuario
            WHERE s.id_solicitud = $1
        `;

        const result = await db.query(query, [id_solicitud]);
        return result.rows[0];
    }

    // Actualizar estado de una solicitud
    static async actualizarSolicitud(id_solicitud, estado, id_certificacion_generada = null) {
        const estadosValidos = ['Pendiente', 'En Proceso', 'Completada', 'Rechazada'];
        
        if (!estadosValidos.includes(estado)) {
            throw new Error(`Estado inválido. Permitidos: ${estadosValidos.join(', ')}`);
        }

        const query = `
            UPDATE solicitud_certificacion 
            SET 
                estado = $2,
                fecha_respuesta = CASE WHEN $2 IN ('Completada', 'Rechazada') THEN CURRENT_DATE ELSE fecha_respuesta END,
                id_certificacion_generada = COALESCE($3, id_certificacion_generada)
            WHERE id_solicitud = $1
            RETURNING *
        `;

        const result = await db.query(query, [id_solicitud, estado, id_certificacion_generada]);
        return result.rows[0];
    }

    // =====================================================
    // 2. GENERACIÓN DE CERTIFICACIONES
    // =====================================================

    // Generar una nueva certificación
    static async generarCertificacion(data) {
        const {
            id_solicitud,
            id_asambleista,
            contenido_json,
            id_usuario_secretaria,
            id_certificacion_sustituye
        } = data;

        // Validar que el asambleísta exista
        const asambleistaCheck = await db.query(
            'SELECT id_asambleista FROM asambleista WHERE id_asambleista = $1',
            [id_asambleista]
        );

        if (asambleistaCheck.rows.length === 0) {
            throw new Error('Asambleísta no encontrado');
        }

        // Generar hash del contenido
        const hash = CryptoService.generarHashFromObject(contenido_json);

        const query = `
            INSERT INTO certificacion_emitida (
                id_solicitud,
                id_asambleista,
                contenido_json,
                hash_seguridad,
                id_usuario_secretaria,
                id_certificacion_sustituye,
                estado,
                fecha_emision
            ) VALUES ($1, $2, $3, $4, $5, $6, 'Activa', CURRENT_DATE)
            RETURNING id_certificacion, folio_unico, hash_seguridad, fecha_emision
        `;

        const result = await db.query(query, [
            id_solicitud || null,
            id_asambleista,
            contenido_json,
            hash,
            id_usuario_secretaria,
            id_certificacion_sustituye || null
        ]);

        // Actualizar la solicitud si existe
        if (id_solicitud) {
            await this.actualizarSolicitud(id_solicitud, 'Completada', result.rows[0].id_certificacion);
        }

        return result.rows[0];
    }

    // Obtener datos consolidados de un asambleísta para la certificación
    static async getDatosConsolidados(id_asambleista) {
        const query = `
            SELECT * FROM v_certificacion_datos_consolidados
            WHERE id_asambleista = $1
        `;

        const result = await db.query(query, [id_asambleista]);
        return result.rows[0] || null;
    }

    // Obtener todas las certificaciones de un asambleísta
    static async getByAsambleista(id_asambleista) {
        const query = `
            SELECT 
                c.id_certificacion,
                c.folio_unico,
                c.hash_seguridad,
                c.fecha_emision,
                c.hora_emision,
                c.estado,
                c.url_pdf,
                a.nombre AS asambleista_nombre,
                a.cedula,
                u.username AS secretaria_nombre
            FROM certificacion_emitida c
            INNER JOIN asambleista a ON c.id_asambleista = a.id_asambleista
            LEFT JOIN sys_usuario u ON c.id_usuario_secretaria = u.id_usuario
            WHERE c.id_asambleista = $1
              AND c.estado != 'Anulada'
            ORDER BY c.fecha_emision DESC
        `;

        const result = await db.query(query, [id_asambleista]);
        return result.rows;
    }

    // Obtener una certificación por folio
    static async getByFolio(folio) {
        const query = `
            SELECT 
                c.*,
                a.nombre AS asambleista_nombre,
                a.cedula,
                a.correo_institucional,
                u.username AS secretaria_nombre,
                v.codigo_verificacion,
                v.url_verificacion,
                v.veces_verificado,
                v.ultima_verificacion,
                v.activo AS verificacion_activa
            FROM certificacion_emitida c
            INNER JOIN asambleista a ON c.id_asambleista = a.id_asambleista
            LEFT JOIN sys_usuario u ON c.id_usuario_secretaria = u.id_usuario
            LEFT JOIN verificacion_externa v ON c.id_certificacion = v.id_certificacion
            WHERE c.folio_unico = $1
        `;

        const result = await db.query(query, [folio]);
        return result.rows[0];
    }

    // Obtener una certificación por ID
    static async getById(id_certificacion) {
        const query = `
            SELECT 
                c.*,
                a.nombre AS asambleista_nombre,
                a.cedula,
                a.correo_institucional,
                u.username AS secretaria_nombre,
                v.codigo_verificacion,
                v.url_verificacion,
                v.veces_verificado,
                v.ultima_verificacion,
                v.activo AS verificacion_activa,
                a2.nombre AS asambleista_original_nombre
            FROM certificacion_emitida c
            INNER JOIN asambleista a ON c.id_asambleista = a.id_asambleista
            LEFT JOIN sys_usuario u ON c.id_usuario_secretaria = u.id_usuario
            LEFT JOIN verificacion_externa v ON c.id_certificacion = v.id_certificacion
            LEFT JOIN certificacion_emitida c2 ON c.id_certificacion_sustituye = c2.id_certificacion
            LEFT JOIN asambleista a2 ON c2.id_asambleista = a2.id_asambleista
            WHERE c.id_certificacion = $1
        `;

        const result = await db.query(query, [id_certificacion]);
        return result.rows[0];
    }

    // =====================================================
    // 3. VERIFICACIÓN DE CERTIFICACIONES
    // =====================================================

    // Verificar una certificación por código
    static async verificarPorCodigo(codigo) {
        const query = `
            SELECT * FROM v_verificacion_certificacion
            WHERE codigo_verificacion = $1
        `;

        const result = await db.query(query, [codigo]);

        if (result.rows.length === 0) {
            return {
                success: false,
                message: 'Código de verificación inválido'
            };
        }

        // Registrar la verificación
        await db.query(
            `SELECT fn_registrar_verificacion_externa($1)`,
            [codigo]
        );

        const data = result.rows[0];
        return {
            success: true,
            data: {
                folio: data.folio_unico,
                estado: data.estado_publico,
                fecha_emision: data.fecha_emision,
                nombre_asambleista: data.nombre_asambleista,
                cedula: data.cedula,
                veces_verificado: data.veces_verificado + 1,
                ultima_verificacion: new Date()
            }
        };
    }

    // =====================================================
    // 4. ANULACIÓN DE CERTIFICACIONES
    // =====================================================

    // Anular una certificación
    static async anular(id_certificacion, motivo, id_usuario_anulacion, id_certificacion_sustituta = null) {
        if (!motivo || motivo.trim() === '') {
            throw new Error('Debe indicar un motivo para anular la certificación');
        }

        // Verificar que la certificación existe y está activa
        const certificacion = await this.getById(id_certificacion);
        if (!certificacion) {
            throw new Error('Certificación no encontrada');
        }

        if (certificacion.estado !== 'Activa') {
            throw new Error(`La certificación está en estado "${certificacion.estado}". Solo se pueden anular certificaciones activas.`);
        }

        // Ejecutar la función de anulación
        await db.query(
            `SELECT fn_anular_certificacion($1, $2, $3, $4)`,
            [id_certificacion, motivo, id_usuario_anulacion, id_certificacion_sustituta || null]
        );

        return {
            success: true,
            message: 'Certificación anulada exitosamente'
        };
    }

    // =====================================================
    // 5. REPORTES Y ESTADÍSTICAS
    // =====================================================

    // Obtener reporte de certificaciones por mes
    static async getReporteMensual() {
        const query = `SELECT * FROM v_reporte_certificaciones_mensual ORDER BY anio DESC, mes DESC`;
        const result = await db.query(query);
        return result.rows;
    }

    // Obtener estadísticas generales de certificaciones
    static async getEstadisticas() {
        const query = `
            SELECT 
                COUNT(*) AS total_certificaciones,
                COUNT(CASE WHEN estado = 'Activa' THEN 1 END) AS activas,
                COUNT(CASE WHEN estado = 'Anulada' THEN 1 END) AS anuladas,
                COUNT(CASE WHEN estado = 'Suspendida' THEN 1 END) AS suspendidas,
                COUNT(DISTINCT id_asambleista) AS asambleistas_distintos,
                MAX(fecha_emision) AS ultima_emision,
                MIN(fecha_emision) AS primera_emision
            FROM certificacion_emitida
        `;

        const result = await db.query(query);
        return result.rows[0];
    }

    // Obtener una certificación para visualizar (con detalles)
    static async getDetalleCompleto(id_certificacion) {
        const query = `
            SELECT 
                c.*,
                a.nombre AS asambleista_nombre,
                a.cedula,
                a.correo_institucional,
                u.username AS secretaria_nombre,
                v.codigo_verificacion,
                v.veces_verificado,
                v.ultima_verificacion,
                v.activo AS verificacion_activa,
                s.estado AS solicitud_estado,
                s.fecha_solicitud,
                s.periodo_desde,
                s.periodo_hasta
            FROM certificacion_emitida c
            INNER JOIN asambleista a ON c.id_asambleista = a.id_asambleista
            LEFT JOIN sys_usuario u ON c.id_usuario_secretaria = u.id_usuario
            LEFT JOIN verificacion_externa v ON c.id_certificacion = v.id_certificacion
            LEFT JOIN solicitud_certificacion s ON c.id_solicitud = s.id_solicitud
            WHERE c.id_certificacion = $1
        `;

        const result = await db.query(query, [id_certificacion]);
        return result.rows[0];
    }
}

module.exports = Certificado;