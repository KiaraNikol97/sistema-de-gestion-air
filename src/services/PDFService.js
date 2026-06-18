// src/services/PDFService.js
// Issue #17 - Generador de Atestados (Certificaciones)
// Servicio para generar PDFs de certificaciones
// Dependencias: puppeteer (para generar PDF desde HTML)
// Para instalar dependencia: npm install puppeteer

const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');
const CryptoService = require('./CryptoService');

class PDFService {
    
    /**
     * Genera un PDF de certificación a partir de HTML
     * @param {Object} datos - Datos de la certificación
     * @param {string} htmlContent - Contenido HTML de la certificación
     * @param {Object} opciones - Opciones adicionales
     * @returns {Promise<Buffer>} PDF generado
     */
    static async generarPDF(datos, htmlContent, opciones = {}) {
        let browser;
        try {
            // Validar que el hash coincida (integridad de los datos)
            if (datos.hash_seguridad) {
                const hashCalculado = CryptoService.generarHashFromObject(datos.contenido || {});
                if (hashCalculado !== datos.hash_seguridad) {
                    throw new Error('El hash de seguridad no coincide. Los datos han sido alterados.');
                }
            }

            // Lanzar el navegador
            browser = await puppeteer.launch({
                headless: 'new',
                args: [
                    '--no-sandbox',
                    '--disable-setuid-sandbox',
                    '--disable-dev-shm-usage',
                    '--disable-accelerated-2d-canvas',
                    '--disable-gpu'
                ]
            });

            const page = await browser.newPage();

            // Configurar el tamaño de página
            await page.setViewport({
                width: 794, // A4 en px a 96dpi
                height: 1123,
                deviceScaleFactor: 1
            });

            // Cargar el contenido HTML
            await page.setContent(htmlContent, {
                waitUntil: 'networkidle0',
                timeout: 30000
            });

            // Generar el PDF
            const pdfBuffer = await page.pdf({
                format: 'A4',
                printBackground: true,
                margin: {
                    top: '15mm',
                    bottom: '15mm',
                    left: '15mm',
                    right: '15mm'
                },
                displayHeaderFooter: true,
                headerTemplate: `
                    <div style="font-size: 8px; color: #999; text-align: center; width: 100%; padding: 5px;">
                        Certificación AIR - Folio: ${datos.folio_unico || 'N/A'}
                    </div>
                `,
                footerTemplate: `
                    <div style="font-size: 8px; color: #999; text-align: center; width: 100%; padding: 5px;">
                        Página <span class="pageNumber"></span> de <span class="totalPages"></span>
                        | Generado: ${new Date().toLocaleDateString()}
                    </div>
                `,
                ...opciones
            });

            return pdfBuffer;

        } catch (error) {
            console.error('Error generando PDF:', error);
            throw new Error(`Error al generar PDF: ${error.message}`);
        } finally {
            if (browser) {
                await browser.close();
            }
        }
    }

    /**
     * Genera un PDF desde una plantilla HTML (usando datos)
     * @param {Object} datosCertificacion - Datos completos de la certificación
     * @returns {Promise<Buffer>} PDF generado
     */
    static async generarDesdePlantilla(datosCertificacion) {
        // Construir el HTML a partir de los datos
        const htmlContent = this.construirHTML(datosCertificacion);
        
        return this.generarPDF(datosCertificacion, htmlContent);
    }

    // Construye el HTML de la certificación a partir de los datos
    static construirHTML(datos) {
        const {
            asambleista,
            folio_unico,
            fecha_emision,
            contenido,
            hash_seguridad,
            codigo_verificacion
        } = datos;

        // Formatear fecha
        const fechaFormateada = fecha_emision 
            ? new Date(fecha_emision).toLocaleDateString('es-CR', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })
            : new Date().toLocaleDateString('es-CR');

        // Construir HTML
        return `
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <title>Certificación AIR - ${folio_unico}</title>
                <style>
                    /* Estilos del certificado */
                    * {
                        margin: 0;
                        padding: 0;
                        box-sizing: border-box;
                    }
                    body {
                        font-family: 'Times New Roman', serif;
                        font-size: 12pt;
                        line-height: 1.6;
                        color: #1a1a2e;
                        background: white;
                        padding: 20px;
                    }
                    .certificado-container {
                        max-width: 210mm;
                        margin: 0 auto;
                        padding: 20px;
                        border: 2px solid #1a1a2e;
                        border-radius: 8px;
                        background: white;
                    }
                    .header {
                        text-align: center;
                        border-bottom: 3px double #1a1a2e;
                        padding-bottom: 15px;
                        margin-bottom: 20px;
                    }
                    .header .logo {
                        font-size: 24pt;
                        font-weight: bold;
                        color: #1a1a2e;
                        letter-spacing: 2px;
                    }
                    .header .subtitulo {
                        font-size: 14pt;
                        color: #555;
                        margin-top: 5px;
                    }
                    .titulo-certificado {
                        text-align: center;
                        font-size: 18pt;
                        font-weight: bold;
                        text-transform: uppercase;
                        margin: 20px 0;
                        letter-spacing: 1px;
                    }
                    .contenido {
                        margin: 20px 0;
                        padding: 0 20px;
                        text-align: justify;
                    }
                    .contenido p {
                        margin-bottom: 10px;
                    }
                    .contenido .asambleista-nombre {
                        font-weight: bold;
                        font-size: 14pt;
                        color: #1a1a2e;
                    }
                    .info-adicional {
                        margin: 20px 0;
                        padding: 15px;
                        background: #f8f9fa;
                        border-radius: 5px;
                        border-left: 4px solid #1a1a2e;
                    }
                    .info-adicional table {
                        width: 100%;
                        border-collapse: collapse;
                        font-size: 11pt;
                    }
                    .info-adicional table td {
                        padding: 6px 8px;
                        border-bottom: 1px solid #e9ecef;
                    }
                    .info-adicional table .label {
                        font-weight: bold;
                        width: 150px;
                        color: #555;
                    }
                    .footer {
                        margin-top: 30px;
                        padding-top: 15px;
                        border-top: 2px solid #1a1a2e;
                        text-align: center;
                        font-size: 10pt;
                        color: #666;
                    }
                    .footer .hash {
                        font-family: 'Courier New', monospace;
                        font-size: 8pt;
                        color: #888;
                        word-break: break-all;
                        background: #f8f9fa;
                        padding: 8px;
                        border-radius: 4px;
                        margin-top: 10px;
                    }
                    .footer .codigo-verificacion {
                        font-size: 14pt;
                        font-weight: bold;
                        color: #1a1a2e;
                        letter-spacing: 2px;
                        margin: 10px 0;
                    }
                    .sello {
                        text-align: center;
                        margin: 20px 0;
                    }
                    .sello .firma {
                        font-family: 'Brush Script MT', cursive;
                        font-size: 18pt;
                        color: #1a1a2e;
                    }
                    .sello .linea-firma {
                        width: 200px;
                        border-bottom: 1px solid #1a1a2e;
                        margin: 0 auto;
                    }
                    .sello .cargo {
                        font-size: 10pt;
                        color: #555;
                    }
                    @media print {
                        body {
                            padding: 0;
                            background: white;
                        }
                        .certificado-container {
                            border: none;
                            border-radius: 0;
                            padding: 10mm;
                        }
                        .no-print {
                            display: none !important;
                        }
                    }
                </style>
            </head>
            <body>
                <div class="certificado-container">
                    <!-- HEADER -->
                    <div class="header">
                        <div class="logo">ASAMBLEA INSTITUCIONAL REPRESENTATIVA</div>
                        <div class="subtitulo">Sistema de Gestión AIR - Certificaciones</div>
                    </div>

                    <!-- TÍTULO -->
                    <div class="titulo-certificado">CERTIFICACIÓN DE PARTICIPACIÓN</div>

                    <!-- CONTENIDO -->
                    <div class="contenido">
                        <p>
                            La <strong>Secretaría de la Asamblea Institucional Representativa</strong>, 
                            en uso de sus facultades legales y reglamentarias,
                        </p>
                        <p style="text-align: center; font-size: 14pt; margin: 20px 0;">
                            <strong>C E R T I F I C A</strong>
                        </p>
                        <p>
                            Que el(la) señor(a) <span class="asambleista-nombre">${asambleista?.nombre || 'N/A'}</span>,
                            identificado(a) con cédula <strong>${asambleista?.cedula || 'N/A'}</strong>,
                            ha participado activamente en las actividades de la Asamblea Institucional Representativa.
                        </p>
                    </div>

                    <!-- INFORMACIÓN ADICIONAL -->
                    <div class="info-adicional">
                        <table>
                            <tr>
                                <td class="label">Folio:</td>
                                <td><strong>${folio_unico || 'N/A'}</strong></td>
                            </tr>
                            <tr>
                                <td class="label">Fecha de emisión:</td>
                                <td>${fechaFormateada}</td>
                            </tr>
                            <tr>
                                <td class="label">Periodo:</td>
                                <td>
                                    ${contenido?.periodo?.desde || 'N/A'} - ${contenido?.periodo?.hasta || 'Actualidad'}
                                </td>
                            </tr>
                            <tr>
                                <td class="label">Total nombramientos:</td>
                                <td>${contenido?.total_nombramientos || 0}</td>
                            </tr>
                            <tr>
                                <td class="label">Asistencias plenarias:</td>
                                <td>${contenido?.total_asistencias_plenarias || 0}</td>
                            </tr>
                            <tr>
                                <td class="label">Propuestas presentadas:</td>
                                <td>${contenido?.total_propuestas || 0}</td>
                            </tr>
                        </table>
                    </div>

                    <!-- SELLO Y FIRMA -->
                    <div class="sello">
                        <div class="firma">_________________________</div>
                        <div class="linea-firma"></div>
                        <div class="cargo">Secretario(a) de la AIR</div>
                        <div style="margin-top: 10px;">
                            <span style="font-size: 10pt; color: #555;">
                                Firma autorizada
                            </span>
                        </div>
                    </div>

                    <!-- FOOTER -->
                    <div class="footer">
                        <div>
                            <strong>Documento electrónico certificado</strong>
                        </div>
                        <div class="codigo-verificacion">
                            Código: ${codigo_verificacion || 'N/A'}
                        </div>
                        <div class="hash">
                            Hash SHA-256: ${hash_seguridad || 'N/A'}
                        </div>
                        <div style="margin-top: 10px; font-size: 8pt; color: #aaa;">
                            Documento generado electrónicamente. Verifique su autenticidad en el portal de la AIR.
                        </div>
                    </div>
                </div>
            </body>
            </html>
        `;
    }

    /**
     * Guarda un PDF en el sistema de archivos
     * @param {Buffer} pdfBuffer - Buffer del PDF
     * @param {string} folio - Folio de la certificación
     * @returns {Promise<string>} Ruta del archivo guardado
     */
    static async guardarPDF(pdfBuffer, folio) {
        const dirPath = path.join(__dirname, '../../certificados');
        
        // Crear directorio si no existe
        if (!fs.existsSync(dirPath)) {
            fs.mkdirSync(dirPath, { recursive: true });
        }

        const filename = `${folio}.pdf`;
        const filePath = path.join(dirPath, filename);

        fs.writeFileSync(filePath, pdfBuffer);
        
        return filePath;
    }

    /**
     * Obtiene un PDF guardado
     * @param {string} folio - Folio de la certificación
     * @returns {Promise<Buffer>} Buffer del PDF
     */
    static async obtenerPDF(folio) {
        const filePath = path.join(__dirname, '../../certificados', `${folio}.pdf`);
        
        if (!fs.existsSync(filePath)) {
            throw new Error(`Certificado ${folio} no encontrado`);
        }

        return fs.readFileSync(filePath);
    }

    /**
     * Elimina un PDF guardado
     * @param {string} folio - Folio de la certificación
     * @returns {Promise<boolean>} True si se eliminó
     */
    static async eliminarPDF(folio) {
        const filePath = path.join(__dirname, '../../certificados', `${folio}.pdf`);
        
        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
            return true;
        }
        
        return false;
    }

    /**
     * Genera un PDF para previsualización (con marca de agua)
     * @param {Object} datos - Datos de la certificación
     * @returns {Promise<Buffer>} PDF con marca de agua
     */
    static async generarPrevisualizacion(datos) {
        const htmlContent = this.construirHTML(datos);
        
        // Agregar marca de agua "PREVISUALIZACIÓN" al HTML
        const htmlConMarca = htmlContent.replace(
            '</style>',
            `
            body::after {
                content: 'PREVISUALIZACIÓN - NO OFICIAL';
                position: fixed;
                top: 50%;
                left: 50%;
                transform: rotate(-45deg) translate(-50%, -50%);
                font-size: 48pt;
                color: rgba(200, 0, 0, 0.15);
                font-weight: bold;
                pointer-events: none;
                z-index: 999;
                white-space: nowrap;
            }
            </style>
            `
        );

        return this.generarPDF(datos, htmlConMarca, {
            format: 'A4',
            printBackground: true,
            margin: { top: '15mm', bottom: '15mm', left: '15mm', right: '15mm' }
        });
    }

    // Vista previa
    static generarHTMLPreview(datos) {
        return this.construirHTML(datos);
    }
}

module.exports = PDFService;