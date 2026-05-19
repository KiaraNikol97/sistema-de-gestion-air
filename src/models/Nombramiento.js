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

        const query = `
            CALL sp_registrar_nombramiento(?, ?, ?, ?, ?, ?, ?, ?)
        `;
        
        const [result] = await db.execute(query, [
            asambleista_id,
            sector_id,
            id_puesto,
            resolucion_id || null,
            fecha_inicio,
            fecha_fin || null,
            id_usuario_registro,
            observaciones || null
        ]);
        
        return result[0]?.id_nombramiento;
    }

    // Finalizar un nombramiento (dar de baja)
    static async finalizar(id_nombramiento, fecha_fin, id_usuario, observacion) {
        const query = `
            CALL sp_finalizar_nombramiento(?, ?, ?, ?)
        `;
        
        await db.execute(query, [id_nombramiento, fecha_fin, id_usuario, observacion]);
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
                    WHEN n.fecha_fin < CURDATE() THEN 'Vencido'
                    ELSE n.estado
                END AS estado_real,
                n.observaciones,
                n.fecha_registro
            FROM nombramiento n
            INNER JOIN asambleista a ON n.asambleista_id = a.asambleista_id
            INNER JOIN catalogo_sector s ON n.sector_id = s.id_sector
            INNER JOIN catalogo_puestos p ON n.id_puesto = p.id_puesto
            WHERE n.asambleista_id = ?
            ORDER BY n.fecha_inicio DESC
        `;
        
        const [rows] = await db.execute(query, [asambleista_id]);
        return rows;
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
            WHERE n.asambleista_id = ?
                AND n.estado = 'Activo'
                AND (n.fecha_fin IS NULL OR n.fecha_fin >= CURDATE())
            LIMIT 1
        `;
        
        const [rows] = await db.execute(query, [asambleista_id]);
        return rows[0] || null;
    }

    // Validar si existe traslape de fechas para un nuevo nombramiento
    static async validarTraslape(asambleista_id, id_puesto, fecha_inicio, fecha_fin) {
        const query = `
            SELECT validar_traslape_nombramiento(?, ?, ?, ?) AS es_valido
        `;
        
        const [result] = await db.execute(query, [
            asambleista_id,
            id_puesto,
            fecha_inicio,
            fecha_fin || '9999-12-31'
        ]);
        
        return result[0]?.es_valido === 1;
    }

    // Obtener todos los nombramientos (para reportes/administración)
    static async getAll(filters = {}) {
        let query = `
            SELECT 
                n.id_nombramiento,
                a.nombres AS asambleista,
                a.cedula,
                s.nombre AS sector,
                p.nombre AS puesto,
                n.fecha_inicio,
                n.fecha_fin,
                n.estado,
                CASE 
                    WHEN n.fecha_fin IS NULL AND n.estado = 'Activo' THEN 'Vigente'
                    WHEN n.fecha_fin < CURDATE() THEN 'Vencido'
                    ELSE n.estado
                END AS estado_real,
                n.fecha_registro
            FROM nombramiento n
            INNER JOIN asambleista a ON n.asambleista_id = a.asambleista_id
            INNER JOIN catalogo_sector s ON n.sector_id = s.id_sector
            INNER JOIN catalogo_puestos p ON n.id_puesto = p.id_puesto
            WHERE 1=1
        `;
        
        const params = [];
        
        if (filters.estado) {
            if (filters.estado === 'Vigente') {
                query += ` AND n.estado = 'Activo' AND (n.fecha_fin IS NULL OR n.fecha_fin >= CURDATE())`;
            } else {
                query += ` AND n.estado = ?`;
                params.push(filters.estado);
            }
        }
        
        if (filters.sector_id) {
            query += ` AND n.sector_id = ?`;
            params.push(filters.sector_id);
        }
        
        query += ` ORDER BY n.fecha_inicio DESC`;
        
        const [rows] = await db.execute(query, params);
        return rows;
    }

    // Obtener reporte de nombramientos agrupado por sector
    static async getReportePorSector() {
        const query = `
            SELECT 
                sector,
                puesto,
                total_nombramientos,
                activos,
                historicos
            FROM v_reporte_nombramientos_sector
        `;
        
        const [rows] = await db.execute(query);
        return rows;
    }
}

module.exports = Nombramiento;
