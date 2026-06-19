
// Archivo principal del servidor - Sistema de Gestión AIR

const express = require('express');
const session = require('express-session');
const path = require('path');
const dotenv = require('dotenv');

// Cargar variables de entorno
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;


// MIDDLEWARE

// Para procesar JSON y formularios
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Archivos estáticos (CSS, JS, imágenes)
app.use(express.static('public'));

// Sesiones (para mantener login)
app.use(session({
    secret: process.env.SESSION_SECRET || 'mi_secreto_para_sesiones',
    resave: false,
    saveUninitialized: false,
    cookie: { 
        secure: false,  // true solo si usa HTTPS
        maxAge: 3600000 // 1 hora
    }
}));

// Servir archivos estáticos de views (HTML, CSS)
app.use('/views', express.static(path.join(__dirname, 'src/views')));
app.use('/shared', express.static(path.join(__dirname, 'src/views/shared')));

// RUTAS PRINCIPALES (SIRVEN LAS VISTAS HTML)


// Página de inicio - redirige según sesión
app.get('/', (req, res) => {
    if (req.session.userId) {
        res.sendFile(path.join(__dirname, 'src/views/seguridad/dashboard.view.html'));
    } else {
        res.sendFile(path.join(__dirname, 'src/views/seguridad/login.view.html'));
    }
});

// Módulo de Asambleístas
app.get('/asambleistas', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/asambleistas/asambleista-lista.view.html'));
});

app.get('/asambleistas/registro', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/asambleistas/asambleista-registro.view.html'));
});

app.get('/asambleistas/editar/:id', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/asambleistas/asambleista-registro.view.html'));
});

app.get('/asambleistas/nombramientos/:id', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/asambleistas/nombramientos-lista.view.html'));
});

// Módulo de Normativa
app.get('/normativa/arbol', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/normativa/reglamento-arbol.view.html'));
});

app.get('/compilador', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/normativa/compilador-visor.view.html'));
});

// Módulo de Sesiones
app.get('/sesiones', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/sesiones/sesion-control-quorum.view.html'));
});

app.get('/sesiones/votacion', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/sesiones/votacion-tablero.view.html'));
});

// Módulo de Certificaciones
app.get('/certificaciones', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/certificaciones/atestados-solicitud.view.html'));
});

app.get('/certificaciones/generar', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/certificaciones/certificado-final.view.html'));
});

// Módulo de Seguridad
app.get('/login', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/seguridad/login.view.html'));
});

app.get('/dashboard', (req, res) => {
    if (req.session.userId) {
        res.sendFile(path.join(__dirname, 'src/views/seguridad/dashboard.view.html'));
    } else {
        res.redirect('/login');
    }
});

app.get('/bitacora', (req, res) => {
    // Solo accesible para Admin y Secretaría
    if (req.session.rol === 'Administrador' || req.session.rol === 'Secretaria_AIR') {
        res.sendFile(path.join(__dirname, 'src/views/seguridad/bitacora.view.html'));
    } else {
        res.status(403).send('Acceso denegado');
    }
});
// Módulo de Comisiones
app.get('/comisiones', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/comisiones/comisiones-lista.view.html'));
});

app.get('/comisiones/registro', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/comisiones/comisiones-registro.view.html'));
});

app.get('/comisiones/editar/:id', (req, res) => {
    res.sendFile(path.join(__dirname, 'src/views/comisiones/comisiones-registro.view.html'));
});


// API ROUTES (importadas desde routes/)

const apiRoutes = require('./src/routes');
app.use('/', apiRoutes);


// MANEJO DE ERROR 404 (ruta no encontrada)
app.use((req, res) => {
    res.status(404).send(`
        <!DOCTYPE html>
        <html>
        <head><title>404 - Página no encontrada</title></head>
        <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1>404</h1>
            <p>La página que buscas no existe.</p>
            <a href="/">Volver al inicio</a>
        </body>
        </html>
    `);
});


// INICIAR SERVIDOR

app.listen(PORT, () => {
    console.log(`
    ╔══════════════════════════════════════════════════╗
    ║     🏛️  SISTEMA DE GESTIÓN AIR - TEC            ║
    ║                                                  ║
    ║     Servidor corriendo en:                      ║
    ║     http://localhost:${PORT}                      ║
    ║                                                  ║
    ║     Credenciales de prueba:                      ║
    ║     admin / Admin123                             ║
    ║     secretaria / Secretaria123                   ║
    ║     asambleista_user / Asamblea123               ║
    ╚══════════════════════════════════════════════════╝
    `);
});