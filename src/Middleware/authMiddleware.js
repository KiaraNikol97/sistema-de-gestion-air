

// Middleware para verificar que el usuario está autenticado
function verificarAutenticacion(req, res, next) {
    if (req.session.userId) {
        next();
    } else {
        res.status(401).json({ success: false, message: 'No autorizado. Inicie sesión primero.' });
    }
}

// Middleware para verificar roles específicos
function verificarRol(rolesPermitidos) {
    return (req, res, next) => {
        if (!req.session.userId) {
            return res.status(401).json({ success: false, message: 'No autenticado' });
        }
        
        if (rolesPermitidos.includes(req.session.rol)) {
            next();
        } else {
            res.status(403).json({ success: false, message: 'Acceso denegado. No tiene permisos suficientes.' });
        }
    };
}

module.exports = { verificarAutenticacion, verificarRol };