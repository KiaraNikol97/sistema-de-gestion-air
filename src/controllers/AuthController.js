// src/controllers/AuthController.js
class AuthController {
    static async login(req, res) {
        const { username, password } = req.body;
        
        // Credenciales de prueba (coinciden con tu SQL)
        const usuarios = {
            admin: { password: 'Admin123', rol: 'Administrador', nombre: 'Administrador' },
            secretaria: { password: 'Secretaria123', rol: 'Secretaria_AIR', nombre: 'Secretaría' },
            asambleista_user: { password: 'Asamblea123', rol: 'Asambleísta', nombre: 'Asambleísta' },
            directorio01: { password: 'Directorio123', rol: 'Directorio', nombre: 'Directorio' },
            consulta01: { password: 'Consulta123', rol: 'Consulta', nombre: 'Consulta' }
        };
        
        const user = usuarios[username];
        
        if (user && user.password === password) {
            req.session.userId = username;
            req.session.rol = user.rol;
            req.session.nombre = user.nombre;
            req.session.username = username;
            
            return res.status(200).json({ 
                success: true, 
                data: { username, rol: user.rol, nombre: user.nombre } 
            });
        } else {
            return res.status(401).json({ 
                success: false, 
                message: "Credenciales incorrectas" 
            });
        }
    }
}

module.exports = AuthController;