// src/services/CryptoService.js
// Servicio de criptografía para generar hashes SHA-256
// Independiente - no depende de SQL

const crypto = require('crypto');

class CryptoService {
    
    /**
     * Genera un hash SHA-256 de un texto
     * @param {string} texto - Texto a hashear
     * @returns {string} Hash en formato hexadecimal
     */
    static generarHash(texto) {
        if (!texto) {
            throw new Error('El texto para generar hash es obligatorio');
        }

        return crypto
            .createHash('sha256')
            .update(texto)
            .digest('hex');
    }

    /**
     * Genera un hash SHA-256 de un objeto JSON
     * @param {Object} objeto - Objeto a convertir a JSON y hashear
     * @returns {string} Hash en formato hexadecimal
     */
    static generarHashFromObject(objeto) {
        if (!objeto || typeof objeto !== 'object') {
            throw new Error('Se requiere un objeto válido para generar hash');
        }

        const texto = JSON.stringify(objeto);
        return this.generarHash(texto);
    }

    /**
     * Genera un hash con timestamp para garantizar unicidad
     * @param {string} texto - Texto base
     * @returns {string} Hash único con timestamp
     */
    static generarHashUnico(texto) {
        const timestamp = Date.now();
        const dato = `${texto}:${timestamp}:${Math.random()}`;
        return this.generarHash(dato);
    }

    /**
     * Verifica si un texto coincide con un hash
     * @param {string} texto - Texto original
     * @param {string} hash - Hash a comparar
     * @returns {boolean} True si coincide
     */
    static verificarHash(texto, hash) {
        if (!texto || !hash) {
            throw new Error('Se requiere texto y hash para verificar');
        }

        const hashCalculado = this.generarHash(texto);
        return hashCalculado === hash;
    }

    /**
     * Genera un código de verificación corto (8 dígitos)
     * @param {string} texto - Texto base
     * @returns {string} Código de 8 dígitos
     */
    static generarCodigoVerificacion(texto) {
        const hash = this.generarHash(texto);
        // Tomar los primeros 8 caracteres del hash
        return hash.substring(0, 8).toUpperCase();
    }
}

module.exports = CryptoService;