const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/db'); // Asumiendo que esta es la ruta de conexión

class AuthController {
    static async login(req, res) {
        const { username, password } = req.body;
        
        try {
            // 1. Buscar usuario 
            const [user] = await db.query('SELECT * FROM sys_usuario WHERE username = ?', [username]);
            
            if (user && await bcrypt.compare(password, user.password_hash)) {
                // 2. Obtener roles del usuario
                const [roles] = await db.query(
                    'SELECT r.nombre_rol FROM sys_rol r JOIN sys_usuario_rol ur ON r.id_rol = ur.id_rol WHERE ur.id_usuario = ?', 
                    [user.id_usuario]
                );
                
                // 3. Generar JWT
                const token = jwt.sign({ 
                    id: user.id_usuario, 
                    roles: roles.map(r => r.nombre_rol) 
                }, process.env.JWT_SECRET || 'secret_key_air', { expiresIn: '8h' });

                // 4. Auditoría: Registro de login exitoso
                await db.query(
                    'INSERT INTO sys_log_auditoria (id_usuario, accion, detalle) VALUES (?, ?, ?)', 
                    [user.id_usuario, 'LOGIN_EXITOSO', 'Usuario autenticado correctamente']
                );

                return res.status(200).json({ token });
            } else {
                // 5. Auditoría: Registro de fallo
                await db.query(
                    'INSERT INTO sys_log_auditoria (accion, detalle) VALUES (?, ?)', 
                    ['LOGIN_FALLIDO', `Intento fallido para el usuario: ${username}`]
                );
                return res.status(401).json({ message: "Credenciales incorrectas" });
            }
        } catch (error) {
            console.error(error);
            res.status(500).json({ error: "Error interno del servidor" });
        }
    }
}

module.exports = AuthController;