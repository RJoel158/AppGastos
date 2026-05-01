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

            // Tabla continua de gastos
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
              columnWidths: {
                0: const pw.FlexColumnWidth(3.0),
                1: const pw.FlexColumnWidth(4.2),
                2: const pw.FlexColumnWidth(2.2),
                3: const pw.FlexColumnWidth(1.4),
                4: const pw.FlexColumnWidth(0.9),
                5: const pw.FlexColumnWidth(1.4),
                6: const pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.teal700,
                  ),
                  children: [
                    _buildTableHeader('Concepto'),
                    _buildTableHeader('Descripción'),
                    _buildTableHeader('Categoría'),
                    _buildTableHeader('Fecha'),
                    _buildTableHeader('Cant.', align: pw.TextAlign.center),
                    _buildTableHeader('Precio U.', align: pw.TextAlign.right),
                    _buildTableHeader('Subtotal', align: pw.TextAlign.right),
                  ],
                ),
                ...gastosOrdenados.asMap().entries.map((entry) {
                  final index = entry.key;
                  final gasto = entry.value;
                  final rowColor =
                      index % 2 == 0 ? PdfColors.white : PdfColors.grey100;
                  final descripcion = gasto.descripcion?.trim() ?? '';
                  final concepto = _truncateText(gasto.nombre, 28);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowColor),
                    children: [
                      _buildCompactCell(
                        concepto,
                        bold: true,
                        color: PdfColors.teal700,
                        fontSize: 8.5,
                        maxLines: 2,
                      ),
                      _buildCompactCell(
                        descripcion.isEmpty ? '-' : descripcion,
                        fontSize: 7.2,
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 2, vertical: 1),
                        color: PdfColors.grey800,
                      ),
                      _buildCompactCell(gasto.categoria, fontSize: 8),
                      _buildCompactCell(
                        dateFormat.format(gasto.fechaCreacion),
                        fontSize: 7.5,
                      ),
                      _buildCompactCell(
                        gasto.cantidad.toString(),
                        align: pw.TextAlign.center,
                        fontSize: 8,
                      ),
                      _buildCompactCell(
                        currencyFormat.format(gasto.precio),
                        align: pw.TextAlign.right,
                        fontSize: 8,
                      ),
                      _buildCompactCell(
                        currencyFormat.format(gasto.subtotal),
                        align: pw.TextAlign.right,
                        fontSize: 8.2,
                        bold: true,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),

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

  static pw.Widget _buildCompactCell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 8,
    PdfColor? color,
    pw.EdgeInsets? padding,
    int? maxLines,
  }) {
    return pw.Padding(
      padding: padding ??
          const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.grey900,
        ),
        textAlign: align,
        maxLines: maxLines,
        softWrap: true,
      ),
    );
  }

  static String _truncateText(String value, int maxChars) {
    final trimmed = value.trim();
    if (trimmed.length <= maxChars) {
      return trimmed;
    }
    return '${trimmed.substring(0, maxChars - 1)}…';
  }

  static pw.Widget _buildHeaderCell(
    String text, {
    required int flex,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          textAlign: align,
        ),
      ),
    );
  }

  static pw.Widget _buildRowCell(
    String text, {
    required int flex,
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor? color,
    double fontSize = 9,
    int? maxLines,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.grey900,
          ),
          textAlign: align,
          maxLines: maxLines,
          softWrap: true,
        ),
      ),
    );
  }
}
