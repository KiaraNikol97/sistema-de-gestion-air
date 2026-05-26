// src/models/Nombramiento.js
const db = require('../config/db');

class Nombramiento {
    
    // Registrar un nuevo nombramiento
    static async create(data) {
        const {
            asambleista_id,
            sector_id,
            id_puesto,
            resolucion_id,
            fecha_inicio,
            fecha_fin,
            id_usuario_registro,
            observaciones
        } = data;

        // Insertar directamente sin procedimiento alamacenado
        const query = `
            INSERT INTO nombramiento (
                id_asambleista, 
                id_sector, 
                id_puesto, 
                resolucion_id,
                fecha_inicio, 
                fecha_fin, 
                id_usuario_registro, 
                observaciones, 
                estado
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'Activo')
            RETURNING id_nombramiento
        `;
        
        const result = await db.query(query, [
            asambleista_id,
            sector_id,
            id_puesto,
            resolucion_id || null,
            fecha_inicio,
            fecha_fin || null,
            id_usuario_registro,
            observaciones || null
        ]);
        
        return result.rows[0]?.id_nombramiento;
    }

    // Finalizar un nombramiento (dar de baja)
    static async finalizar(id_nombramiento, fecha_fin, id_usuario, observacion) {
        const query = `
        UPDATE nombramiento 
        SET estado = 'Finalizado', 
        fecha_fin = $1, 
        observaciones = COALESCE(observaciones || E'\n', '') || $2
        WHERE id_nombramiento = $3
        RETURNING 
        `;
        
        const result = await db.query(query, [fecha_fin, observacion, id_nombramiento]);
        
        if (result.rows.length === 0) {
            throw new Error('No se encontró el nombramiento');
        }

        // Registrar en Auditoria
        await db.query(
            'INSERT INTO sys_log_auditoria (id_usuario, accion, tabla_afectada, detalle) VALUES ($1, $2, $3, $4)',
            [id_usuario, 'UPDATE', 'nombramiento', `Finalizado nombramiento ${id_nombramiento}`]
        );

    }


    // Obtener historial completo de nombramientos de un asambleísta
    static async getHistorialByAsambleistaId(asambleista_id) {
        const query = `
            SELECT 
                n.id_nombramiento,
                n.asambleista_id,
                a.nombres AS asambleista_nombre,
                a.cedula,
                s.id_sector,
                s.nombre AS sector,
                p.id_puesto,
                p.nombre AS puesto,
                n.resolucion_id,
                n.fecha_inicio,
                n.fecha_fin,
                n.estado,
                CASE 
                    WHEN n.fecha_fin IS NULL AND n.estado = 'Activo' THEN 'Vigente'
                    WHEN n.fecha_fin < CURRENT_DATE() THEN 'Vencido'
                    ELSE n.estado
                END AS estado_real,
                n.observaciones,
                n.fecha_registro
            FROM nombramiento n
            INNER JOIN asambleista a ON n.asambleista_id = a.asambleista_id
            INNER JOIN catalogo_sector s ON n.sector_id = s.id_sector
            INNER JOIN catalogo_puestos p ON n.id_puesto = p.id_puesto
            WHERE n.asambleista_id = $1
            ORDER BY n.fecha_inicio DESC
        `;
        
        const result = await db.query(query, [asambleista_id]);
        return result.rows;
    }

    // Obtener el nombramiento vigente actual de un asambleísta
    static async getVigenteByAsambleistaId(asambleista_id) {
        const query = `
            SELECT 
                n.id_nombramiento,
                n.asambleista_id,
                s.id_sector,
                s.nombre AS sector,
                p.id_puesto,
                p.nombre AS puesto,
                n.fecha_inicio,
                n.fecha_fin,
                n.estado,
                n.observaciones
            FROM nombramiento n
            INNER JOIN catalogo_sector s ON n.sector_id = s.id_sector
            INNER JOIN catalogo_puestos p ON n.id_puesto = p.id_puesto
            WHERE n.asambleista_id = $1
                AND n.estado = 'Activo'
                AND (n.fecha_fin IS NULL OR n.fecha_fin >= CURRENT_DATE())
            LIMIT 1
        `;
        
        const result = await db.query(query, [asambleista_id]);
        return result.rows[0] || null;
    }

    // Validar si existe traslape de fechas para un nuevo nombramiento
    static async validarTraslape(asambleista_id, id_puesto, fecha_inicio, fecha_fin) {
        const query = `
            SELECT fn_validar_traslape_nombramiento_directo($1, $2, $3, $4) AS es_valido
        `;
        
        const fechaFinParam = fecha_fin || '9999-12-31';
        const result = await db.query(query, [asambleista_id, id_puesto, fecha_inicio, fechaFinParam]);
        
        return result.rows[0]?.es_valido === true;
    }

    static async getAll(filters = {}) {
        let query = `
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
                n.fecha_registro
            FROM nombramiento n
            INNER JOIN asambleista a ON n.id_asambleista = a.id_asambleista
            INNER JOIN catalogo_sector s ON n.id_sector = s.id_sector
            INNER JOIN catalogo_puestos p ON n.id_puesto = p.id_puesto
            WHERE 1=1
        `;
        
        const params = [];
        let paramCount = 1;
        
        if (filters.estado) {
            if (filters.estado === 'Vigente') {
                query += ` AND n.estado = 'Activo' AND (n.fecha_fin IS NULL OR n.fecha_fin >= CURRENT_DATE)`;
            } else {
                query += ` AND n.estado = $${paramCount}`;
                params.push(filters.estado);
                paramCount++;
            }
        }
        
        if (filters.sector_id) {
            query += ` AND n.id_sector = $${paramCount}`;
            params.push(filters.sector_id);
        }
        
        query += ` ORDER BY n.fecha_inicio DESC`;
        
        const result = await db.query(query, params);
        return result.rows;
    }

    static async getReportePorSector() {
        const query = `
            SELECT 
                s.nombre AS sector,
                p.nombre_puesto AS puesto,
                COUNT(n.id_nombramiento) AS total_nombramientos,
                COUNT(CASE WHEN n.estado = 'Activo' AND (n.fecha_fin IS NULL OR n.fecha_fin >= CURRENT_DATE) THEN 1 END) AS activos,
                COUNT(CASE WHEN n.estado = 'Finalizado' OR n.fecha_fin < CURRENT_DATE THEN 1 END) AS historicos
            FROM nombramiento n
            INNER JOIN catalogo_sector s ON n.id_sector = s.id_sector
            INNER JOIN catalogo_puestos p ON n.id_puesto = p.id_puesto
            GROUP BY s.nombre, p.nombre_puesto
            ORDER BY s.nombre, p.nombre_puesto
        `;
        
        const result = await db.query(query);
        return result.rows;
    }
}

module.exports = Nombramiento;
