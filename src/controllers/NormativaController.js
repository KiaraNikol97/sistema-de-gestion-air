// src/controllers/NormativaController.js
const db = require('../config/db');

class NormativaController {
    
    // Obtener lista de reglamentos
    async getReglamentos(req, res) {
        try {
            const result = await db.query('SELECT id_reglamento, nombre_normativa, sigla FROM reglamento WHERE activo = TRUE');
            res.json({ success: true, data: result.rows });
        } catch (error) {
            console.error('Error:', error);
            res.status(500).json({ success: false, message: 'Error al cargar reglamentos' });
        }
    }
    
    // Obtener árbol de normativa
    async getArbol(req, res) {
        try {
            const result = await db.query(`
                SELECT e.id_elemento as id, e.numero_etiqueta as numero, 
                       e.contenido_texto as titulo, e.id_elemento_padre as padre,
                       ev.nombre as estado
                FROM elemento_normativo e
                JOIN catalogo_estado_vigencia ev ON e.id_estado_vigencia = ev.id_estado_vigencia
                WHERE ev.nombre = 'Vigente'
                ORDER BY e.orden
            `);
            
            function buildTree(items, parentId = null) {
                const result = [];
                for (const item of items) {
                    if ((item.padre === parentId) || (parentId === null && item.padre === null)) {
                        result.push({
                            id: item.id,
                            numero: item.numero,
                            titulo: item.titulo?.substring(0, 100) || '',
                            resumen: item.titulo?.substring(0, 80) + '...' || '',
                            estado: item.estado,
                            hijos: buildTree(items, item.id)
                        });
                    }
                }
                return result;
            }
            
            const arbol = buildTree(result.rows);
            res.json({ success: true, data: arbol });
        } catch (error) {
            console.error('Error:', error);
            res.status(500).json({ success: false, message: 'Error al cargar árbol' });
        }
    }
    
    // Obtener artículo por ID
    async getArticulo(req, res) {
        try {
            const { id } = req.params;
            const result = await db.query(`
                SELECT e.id_elemento, e.numero_etiqueta, e.contenido_texto,
                       e.fecha_inicio_vigencia, e.fecha_fin_vigencia, ev.nombre as estado
                FROM elemento_normativo e
                JOIN catalogo_estado_vigencia ev ON e.id_estado_vigencia = ev.id_estado_vigencia
                WHERE e.id_elemento = $1
            `, [id]);
            
            if (result.rows.length === 0) {
                return res.status(404).json({ success: false, message: 'No encontrado' });
            }
            
            res.json({ success: true, data: result.rows[0] });
        } catch (error) {
            console.error('Error:', error);
            res.status(500).json({ success: false, message: 'Error al cargar artículo' });
        }
    }
    
    // Obtener compilado histórico
    async getCompilado(req, res) {
        const { id } = req.params;
        const { fecha } = req.query;
        
        let fechaConsulta = fecha ? new Date(fecha) : new Date();
        const hoy = new Date();
        if (fechaConsulta > hoy) fechaConsulta = hoy;
        const fechaStr = fechaConsulta.toISOString().split('T')[0];
        
        try {
            const reglamentoResult = await db.query(
                'SELECT id_reglamento, nombre_normativa, sigla FROM reglamento WHERE id_reglamento = $1 AND activo = TRUE',
                [id]
            );
            
            if (reglamentoResult.rows.length === 0) {
                return res.status(404).json({ success: false, message: 'Reglamento no encontrado' });
            }
            
            const elementosResult = await db.query(`
                SELECT 
                    e.id_elemento,
                    e.numero_etiqueta,
                    e.contenido_texto,
                    e.fecha_inicio_vigencia,
                    e.fecha_fin_vigencia
                FROM elemento_normativo e
                WHERE e.id_reglamento = $1
                  AND e.fecha_inicio_vigencia <= $2
                  AND (e.fecha_fin_vigencia IS NULL OR e.fecha_fin_vigencia > $2)
                ORDER BY e.orden
            `, [id, fechaStr]);
            
            const esVersionHistorica = fechaConsulta < new Date();
            
            res.json({
                success: true,
                data: {
                    reglamento: reglamentoResult.rows[0],
                    fecha_consulta: fechaStr,
                    es_version_historica: esVersionHistorica,
                    total_articulos: elementosResult.rows.length,
                    articulos: elementosResult.rows
                }
            });
        } catch (error) {
            console.error('Error:', error);
            res.status(500).json({ success: false, message: 'Error al cargar compilado' });
        }
    }
}

module.exports = NormativaController;