import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';

class PdfService {
  static Future<void> generarReporteGastos({
    required List<Producto> gastos,
    String? categoriaFiltro,
    double? precioMin,
    double? precioMax,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final pdf = pw.Document();
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Ordenar gastos de más antiguo a más reciente
    final gastosOrdenados = List<Producto>.from(gastos)
      ..sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));

    // Calcular totales
    final totalGeneral =
        gastosOrdenados.fold(0.0, (sum, gasto) => sum + gasto.subtotal);

    // Agrupar por categoría
    final Map<String, double> totalesPorCategoria = {};
    final Map<String, int> cantidadPorCategoria = {};
    for (var gasto in gastosOrdenados) {
      totalesPorCategoria[gasto.categoria] =
          (totalesPorCategoria[gasto.categoria] ?? 0) + gasto.subtotal;
      cantidadPorCategoria[gasto.categoria] =
          (cantidadPorCategoria[gasto.categoria] ?? 0) + 1;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return [
            // Encabezado principal
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'REPORTE DE GASTOS',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal700,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Control de Gastos Personales',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Fecha de emisión',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.Text(
                            dateFormat.format(DateTime.now()),
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 2, color: PdfColors.teal700),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // Filtros aplicados
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FILTROS APLICADOS',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildFiltroItem(
                          'Categoría',
                          categoriaFiltro ?? 'Todas',
                        ),
                      ),
                      pw.Expanded(
                        child: _buildFiltroItem(
                          'Rango de precio',
                          precioMin != null || precioMax != null
                              ? '${currencyFormat.format(precioMin ?? 0)} - ${currencyFormat.format(precioMax ?? 10000)}'
                              : 'Sin filtro',
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  _buildFiltroItem(
                    'Período',
                    fechaInicio != null || fechaFin != null
                        ? '${fechaInicio != null ? dateFormat.format(fechaInicio) : 'Inicio'} - ${fechaFin != null ? dateFormat.format(fechaFin) : 'Fin'}'
                        : 'Todo el historial',
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Resumen general
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                border: pw.Border.all(color: PdfColors.teal700, width: 2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TOTAL GENERAL',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal700,
                        ),
                      ),
                      pw.Text(
                        '${gastosOrdenados.length} registro${gastosOrdenados.length != 1 ? 's' : ''}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    currencyFormat.format(totalGeneral),
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal700,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // Tabla de gastos
            pw.Text(
              'DETALLE DE GASTOS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal700,
              ),
            ),
            pw.SizedBox(height: 8),

            // Encabezado de la tabla
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.teal700,
                  ),
                  children: [
                    _buildTableHeader('Concepto / Descripción'),
                    _buildTableHeader('Categoría'),
                    _buildTableHeader('Fecha'),
                    _buildTableHeader('Cant.'),
                    _buildTableHeader('Precio U.'),
                    _buildTableHeader('Subtotal'),
                  ],
                ),
              ],
            ),

            // Filas de gastos (se pueden dividir entre páginas)
            ...gastosOrdenados.map((gasto) {
              return pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: gastosOrdenados.indexOf(gasto) % 2 == 0
                          ? PdfColors.white
                          : PdfColors.grey100,
                    ),
                    children: [
                      _buildConceptoDescripcionCell(gasto.nombre, gasto.descripcion),
                      _buildTableCell(gasto.categoria),
                      _buildTableCell(
                        dateFormat.format(gasto.fechaCreacion),
                        fontSize: 8,
                      ),
                      _buildTableCell(
                        gasto.cantidad.toString(),
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        currencyFormat.format(gasto.precio),
                        align: pw.TextAlign.right,
                      ),
                      _buildTableCell(
                        currencyFormat.format(gasto.subtotal),
                        align: pw.TextAlign.right,
                        bold: true,
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),

            pw.SizedBox(height: 24),

            // Resumen por categoría
            pw.Text(
              'RESUMEN POR CATEGORÍA',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal700,
              ),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.teal700,
                  ),
                  children: [
                    _buildTableHeader('Categoría'),
                    _buildTableHeader('Cantidad'),
                    _buildTableHeader('Total'),
                  ],
                ),
                ...totalesPorCategoria.entries.map((entry) {
                  final categoria = entry.key;
                  final total = entry.value;
                  final cantidad = cantidadPorCategoria[categoria] ?? 0;
                  final porcentaje =
                      (total / totalGeneral * 100).toStringAsFixed(1);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color:
                          totalesPorCategoria.keys.toList().indexOf(categoria) %
                                      2 ==
                                  0
                              ? PdfColors.white
                              : PdfColors.grey100,
                    ),
                    children: [
                      _buildTableCell(categoria, bold: true),
                      _buildTableCell(
                        cantidad.toString(),
                        align: pw.TextAlign.center,
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              currencyFormat.format(total),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              '$porcentaje%',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
                // Total final
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.teal700,
                  ),
                  children: [
                    _buildTableHeader('TOTAL', align: pw.TextAlign.right),
                    _buildTableHeader(
                      gastosOrdenados.length.toString(),
                      align: pw.TextAlign.center,
                    ),
                    _buildTableHeader(
                      currencyFormat.format(totalGeneral),
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          );
        },
      ),
    );

    // Mostrar diálogo de impresión/compartir
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          'reporte_gastos_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildFiltroItem(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 9,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
        maxLines: 3,
        softWrap: true,
      ),
    );
  }

  static pw.Widget _buildConceptoDescripcionCell(String concepto, String? descripcion) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            concepto,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal700,
            ),
            maxLines: 2,
            softWrap: true,
          ),
          if (descripcion != null && descripcion.isNotEmpty)
            pw.SizedBox(height: 2),
          if (descripcion != null && descripcion.isNotEmpty)
            pw.Text(
              descripcion,
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey700,
              ),
              maxLines: 2,
              softWrap: true,
            ),
        ],
      ),
    );
  }
}
