const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User'); 

class AuthController {
    static async login(req, res) {
        const { username, password } = req.body;
        
        try {
            // 1. Buscar usuario usando el Modelo
            const user = await User.findByUsername(username);
            
            if (user && await bcrypt.compare(password, user.password_hash)) {
                // 2. Obtener roles usando el Modelo
                const roles = await User.getRoles(user.id_usuario);
                
                // 3. Generar JWT
                const token = jwt.sign({ 
                    id: user.id_usuario, 
                    roles: roles 
                }, process.env.JWT_SECRET || 'secret_key_air', { expiresIn: '8h' });

                // 4. Auditoría: Login exitoso usando el Modelo
                await User.registrarAuditoria(user.id_usuario, 'LOGIN_EXITOSO', 'Usuario autenticado correctamente');

                return res.status(200).json({ token });
            } else {
                // 5. Auditoría: Fallo usando el Modelo
                await User.registrarAuditoria(null, 'LOGIN_FALLIDO', `Intento fallido para el usuario: ${username}`);
                return res.status(401).json({ message: "Credenciales incorrectas" });
            }
        } catch (error) {
            console.error(error);
            res.status(500).json({ error: "Error interno del servidor" });
        }
    }
}

module.exports = AuthController;