const jwt = require('jsonwebtoken');

const authorize = (rolesPermitidos = []) => {
    return (req, res, next) => {
        // Obtener el token del encabezado Authorization
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            return res.status(403).json({ message: "Acceso denegado: No se proporcionó token" });
        }

        jwt.verify(token, process.env.JWT_SECRET || 'secret_key_air', (err, decoded) => {
            if (err) {
                return res.status(401).json({ message: "Token inválido o expirado" });
            }

            // Verificar si el usuario tiene el rol necesario
            const tieneRol = decoded.roles.some(rol => rolesPermitidos.includes(rol));
            
            if (rolesPermitidos.length && !tieneRol) {
                return res.status(403).json({ message: "No tienes permiso para realizar esta acción" });
            }

            req.user = decoded;
            next();
        });
    };
};

module.exports = authorize;