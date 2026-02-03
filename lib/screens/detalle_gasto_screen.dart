import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';
import '../models/categoria_gasto.dart';

class DetalleGastoScreen extends StatelessWidget {
  final Producto gasto;

  const DetalleGastoScreen({super.key, required this.gasto});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final categoria = CategoriaGasto.obtenerCategoria(gasto.categoria);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen de fondo
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Color(categoria.color),
            flexibleSpace: FlexibleSpaceBar(
              background: gasto.imagenPath != null
                  ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _ImagenPantallaCompleta(
                              imagePath: gasto.imagenPath!,
                              categoria: categoria,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'gasto_${gasto.id}',
                            child: Image.file(
                              File(gasto.imagenPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Color(categoria.color)
                                      .withValues(alpha: 0.2),
                                  child: Center(
                                    child: Text(
                                      categoria.icono,
                                      style: const TextStyle(fontSize: 120),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      color: Color(categoria.color).withValues(alpha: 0.2),
                      child: Center(
                        child: Text(
                          categoria.icono,
                          style: const TextStyle(fontSize: 120),
                        ),
                      ),
                    ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y categoría
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          gasto.nombre,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Badge de categoría
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(categoria.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          categoria.icono,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          gasto.categoria,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(categoria.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Fecha y hora
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${gasto.fechaCreacion.day}/${gasto.fechaCreacion.month}/${gasto.fechaCreacion.year} a las ${gasto.fechaCreacion.hour.toString().padLeft(2, '0')}:${gasto.fechaCreacion.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Descripción
                  if (gasto.descripcion != null &&
                      gasto.descripcion!.isNotEmpty) ...[
                    Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gasto.descripcion!,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Detalles financieros
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF57CC99).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF57CC99).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Precio unitario',
                          currencyFormat.format(gasto.precio),
                          Icons.attach_money,
                          isDark,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Cantidad',
                          '${gasto.cantidad}',
                          Icons.shopping_cart,
                          isDark,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Total',
                          currencyFormat.format(gasto.subtotal),
                          Icons.payments,
                          isDark,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    bool isDark, {
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF57CC99).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF57CC99),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 24 : 18,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal
                ? const Color(0xFF57CC99)
                : (isDark ? Colors.white : const Color(0xFF2C3E50)),
          ),
        ),
      ],
    );
  }
}

class _ImagenPantallaCompleta extends StatelessWidget {
  final String imagePath;
  final CategoriaGasto categoria;

  const _ImagenPantallaCompleta({
    required this.imagePath,
    required this.categoria,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  categoria.icono,
                  style: const TextStyle(fontSize: 120, color: Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
