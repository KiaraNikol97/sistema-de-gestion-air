// src/models/NormativaModel.js
// Descripción: Modelo para gestión de normativa (recursividad)
// Dependencias: mysql2/promise

const pool = require('../../config/db');

class NormativaModel {
    
    // Obtener todos los reglamentos activos
    async getAllReglamentos() {
        const [rows] = await pool.query(
            'SELECT id_reglamento, nombre_normativa, sigla FROM reglamento WHERE activo = true ORDER BY nombre_normativa'
        );
        return rows;
    }
    
    // Obtener un reglamento por ID
    async getReglamentoById(id_reglamento) {
        const [rows] = await pool.query(
            'SELECT * FROM reglamento WHERE id_reglamento = ?',
            [id_reglamento]
        );
        return rows[0];
    }
    
    // Obtener todos los niveles de reglamento
    async getNiveles() {
        const [rows] = await pool.query(
            'SELECT id_nivel_reglamento, nombre, orden FROM catalogo_nivel_reglamento WHERE activo = true ORDER BY orden'
        );
        return rows;
    }
    
    // Obtener el árbol completo de un reglamento (RECURSIVIDAD)
    async getArbolReglamento(id_reglamento) {
        // Usar la función SQL que creamos en la Parte 2
        const [rows] = await pool.query(
            'SELECT obtener_arbol_reglamento(?) AS arbol',
            [id_reglamento]
        );
        return rows[0]?.arbol ? JSON.parse(rows[0].arbol) : [];
    }
    
    // Obtener un elemento normativo por ID
    async getElementoById(id_elemento) {
        const [rows] = await pool.query(
            `SELECT e.*, n.nombre AS nivel_nombre, r.sigla AS reglamento_sigla
             FROM elemento_normativo e
             JOIN catalogo_nivel_reglamento n ON e.id_nivel_reglamento = n.id_nivel_reglamento
             JOIN reglamento r ON e.id_reglamento = r.id_reglamento
             WHERE e.id_elemento = ?`,
            [id_elemento]
        );
        return rows[0];
    }
    
    // Verificar si existe una versión vigente del mismo elemento
    async existeVersionVigente(id_reglamento, numero_etiqueta, id_elemento_padre) {
        const [rows] = await pool.query(
            `SELECT COUNT(*) as total FROM elemento_normativo 
             WHERE id_reglamento = ? 
               AND numero_etiqueta = ? 
               AND COALESCE(id_elemento_padre, 0) = COALESCE(?, 0)
               AND id_estado_vigencia = 1
               AND fecha_fin_vigencia IS NULL`,
            [id_reglamento, numero_etiqueta, id_elemento_padre || 0]
        );
        return rows[0].total > 0;
    }
    
    // Crear nuevo elemento normativo
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
        
        const [result] = await pool.query(
            `INSERT INTO elemento_normativo 
             (id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta, 
              contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
             VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)`,
            [id_reglamento, id_elemento_padre || null, id_nivel_reglamento, numero_etiqueta,
             contenido_texto, orden, fecha_inicio_vigencia, id_usuario_registro]
        );
        
        return result.insertId;
    }
    
    // Publicar nueva versión de un elemento
    async publicarNuevaVersion(id_elemento_anterior, nuevo_texto, fecha_inicio, id_usuario_registro) {
        // Obtener el elemento anterior
        const elementoAnterior = await this.getElementByIdoById(id_elemento_anterior);
        
        if (!elementoAnterior) {
            throw new Error('Elemento original no encontrado');
        }
        
        // Crear nuevo elemento (el trigger tg_vigencia_normativa se encarga del versionamiento)
        const [result] = await pool.query(
            `INSERT INTO elemento_normativo 
             (id_reglamento, id_elemento_padre, id_nivel_reglamento, numero_etiqueta, 
              contenido_texto, orden, fecha_inicio_vigencia, id_estado_vigencia, id_usuario_registro)
             VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)`,
            [elementoAnterior.id_reglamento, elementoAnterior.id_elemento_padre, 
             elementoAnterior.id_nivel_reglamento, elementoAnterior.numero_etiqueta,
             nuevo_texto, elementoAnterior.orden, fecha_inicio, id_usuario_registro]
        );
        
        return result.insertId;
    }
    
    // Verificar si un elemento tiene hijos (para no borrarlo)
    async tieneHijos(id_elemento) {
        const [rows] = await pool.query(
            'SELECT tiene_hijos(?) AS tiene',
            [id_elemento]
        );
        return rows[0].tiene === 1;
    }
    
    // Obtener ruta completa de un elemento
    async getRutaElemento(id_elemento) {
        const [rows] = await pool.query(
            'SELECT obtener_ruta_elemento(?) AS ruta',
            [id_elemento]
        );
        return rows[0]?.ruta || '';
    }
    
    // Eliminar elemento (solo si no tiene hijos)
    async eliminarElemento(id_elemento) {
        const tiene = await this.tieneHijos(id_elemento);
        if (tiene) {
            throw new Error('No se puede eliminar un elemento que tiene hijos');
        }
        
        const [result] = await pool.query(
            'DELETE FROM elemento_normativo WHERE id_elemento = ?',
            [id_elemento]
        );
        return result.affectedRows > 0;
    }
}

module.exports = NormativaModel;
