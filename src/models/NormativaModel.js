// CORREGIDO para PostgreSQL/Supabase

const db = require('../config/db');

class NormativaModel {
    
    async getAllReglamentos() {
        const result = await db.query(
            'SELECT id_reglamento, nombre_normativa, sigla FROM reglamento WHERE activo = true ORDER BY nombre_normativa'
        );
        return result.rows;
    }
    
    async getReglamentoById(id_reglamento) {
        const result = await db.query(
            'SELECT * FROM reglamento WHERE id_reglamento = $1',
            [id_reglamento]
        );
        return result.rows[0];
    }
    
    async getNiveles() {
        const result = await db.query(
            'SELECT id_nivel_reglamento, nombre, orden FROM catalogo_nivel_reglamento WHERE activo = true ORDER BY orden'
        );
        return result.rows;
    }
    
    // Función recursiva para obtener el árbol (usando CTE en PostgreSQL)
    async getArbolReglamento(id_reglamento) {
        const query = `
            WITH RECURSIVE arbol_normativo AS (
                -- Nivel raíz: elementos sin padre
                SELECT 
                    e.id_elemento,
                    e.numero_etiqueta,
                    e.contenido_texto,
                    e.id_nivel_reglamento,
                    e.orden,
                    n.nombre AS nivel_nombre,
                    0 AS profundidad,
                    ARRAY[e.orden] AS orden_path
                FROM elemento_normativo e
                JOIN catalogo_nivel_reglamento n ON e.id_nivel_reglamento = n.id_nivel_reglamento
                WHERE e.id_reglamento = $1
                  AND e.id_elemento_padre IS NULL
                  AND e.fecha_fin_vigencia IS NULL
                
                UNION ALL
                
                -- Nivel hijo
                SELECT 
                    e.id_elemento,
                    e.numero_etiqueta,
                    e.contenido_texto,
                    e.id_nivel_reglamento,
                    e.orden,
                    n.nombre AS nivel_nombre,
                    a.profundidad + 1,
                    a.orden_path || e.orden
                FROM elemento_normativo e
                JOIN catalogo_nivel_reglamento n ON e.id_nivel_reglamento = n.id_nivel_reglamento
                JOIN arbol_normativo a ON e.id_elemento_padre = a.id_elemento
                WHERE e.fecha_fin_vigencia IS NULL
            )
            SELECT * FROM arbol_normativo
            ORDER BY orden_path
        `;
        
        const result = await db.query(query, [id_reglamento]);
        return result.rows;
    }
    
    async getElementoById(id_elemento) {
        const result = await db.query(
            `SELECT e.*, n.nombre AS nivel_nombre, r.sigla AS reglamento_sigla
             FROM elemento_normativo e
             JOIN catalogo_nivel_reglamento n ON e.id_nivel_reglamento = n.id_nivel_reglamento
             JOIN reglamento r ON e.id_reglamento = r.id_reglamento
             WHERE e.id_elemento = $1`,
            [id_elemento]
        );
        return result.rows[0];
    }
    
    async existeVersionVigente(id_reglamento, numero_etiqueta, id_elemento_padre) {
        const result = await db.query(
            `SELECT COUNT(*) as total FROM elemento_normativo 
             WHERE id_reglamento = $1 
               AND numero_etiqueta = $2 
               AND COALESCE(id_elemento_padre, 0) = COALESCE($3, 0)
               AND id_estado_vigencia = 1
               AND fecha_fin_vigencia IS NULL`,
            [id_reglamento, numero_etiqueta, id_elemento_padre || 0]
        );
        return parseInt(result.rows[0].total) > 0;
    }
    
    async crearElemento(datos) {
        const {
            id_reglamento,
            id_elemento_padre,
            id_nivel_reglamento,
            numero_etiqueta,
            contenido_texto,
            orden,
            fecha_inicio_vigencia,
            id_usuario_registro
        } = datos;
        
        const result = await db.query(
            `INSERT INTO elemento_normativo 
             (id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta, 
              contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
             VALUES ($1, $2, $3, $4, $5, $6, $7, 1, $8)
             RETURNING id_elemento`,
            [id_reglamento, id_elemento_padre || null, id_nivel_reglamento, numero_etiqueta,
             contenido_texto, orden, fecha_inicio_vigencia, id_usuario_registro]
        );
        
        return result.rows[0].id_elemento;
    }
    
    async publicarNuevaVersion(id_elemento_anterior, nuevo_texto, fecha_inicio, id_usuario_registro) {
        const elementoAnterior = await this.getElementByIdoById(id_elemento_anterior);
        
        if (!elementoAnterior) {
            throw new Error('Elemento original no encontrado');
        }
        
        // El trigger tg_versionar_elemento_normativo maneja la desactivación de la versión anterior
        const result = await db.query(
            `INSERT INTO elemento_normativo 
             (id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta, 
              contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
             VALUES ($1, $2, $3, $4, $5, $6, $7, 1, $8)
             RETURNING id_elemento`,
            [elementoAnterior.id_reglamento, elementoAnterior.id_elemento_padre, 
             elementoAnterior.id_nivel_reglamento, elementoAnterior.numero_etiqueta,
             nuevo_texto, elementoAnterior.orden, fecha_inicio, id_usuario_registro]
        );
        
        return result.rows[0].id_elemento;
    }
    
    async tieneHijos(id_elemento) {
        const result = await db.query(
            'SELECT COUNT(*) as total FROM elemento_normativo WHERE id_elemento_padre = $1 AND fecha_fin_vigencia IS NULL',
            [id_elemento]
        );
        return parseInt(result.rows[0].total) > 0;
    }
    
    async eliminarElemento(id_elemento) {
        const tiene = await this.tieneHijos(id_elemento);
        if (tiene) {
            throw new Error('No se puede eliminar un elemento que tiene hijos');
        }
        
        const result = await db.query(
            'DELETE FROM elemento_normativo WHERE id_elemento = $1',
            [id_elemento]
        );
        return result.rowCount > 0;
    }
}

module.exports = NormativaModel;
