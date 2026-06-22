const db = require('../config/db');

class User {
    // 1. Buscar un usuario por su username (Para el Login)
    static async findByUsername(username) {
        const resultado = await db.query('SELECT * FROM sys_usuario WHERE username = $1', [username]);
        return resultado.rows[0]; // Retorna el usuario si existe, o undefined
    }

    // 2. Obtener los roles que tiene asignados un usuario (Para el JWT)
    static async getRoles(id_usuario) {
        const resultado = await db.query(
            `SELECT r.nombre_rol 
             FROM sys_rol r 
             JOIN sys_usuario_rol ur ON r.id_rol = ur.id_rol 
             WHERE ur.id_usuario = $1`, 
            [id_usuario]
        );
        return resultado.rows.map(row => row.nombre_rol); // Retorna un arreglo de strings
    }

    // 3. Registrar un evento en la bitácora de auditoría
    static async registrarAuditoria(id_usuario, accion, detalle) {
        await db.query(
            'INSERT INTO sys_log_auditoria (id_usuario, accion, detalle) VALUES ($1, $2, $3)',
            [id_usuario || null, accion, detalle]
        );
    }
}

module.exports = User;
