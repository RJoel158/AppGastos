import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';
import '../models/categoria_gasto.dart';

class GastoCard extends StatelessWidget {
  final Producto gasto;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;
  final VoidCallback onEliminar;
  final VoidCallback onEditar;

  const GastoCard({
    super.key,
    required this.gasto,
    required this.onIncrementar,
    required this.onDecrementar,
    required this.onEliminar,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final categoria = CategoriaGasto.obtenerCategoria(gasto.categoria);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onEditar,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen o ícono
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: Color(categoria.color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Color(categoria.color).withValues(alpha: 0.3),
                          width: 1.5),
                    ),
                    child: gasto.imagenPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Hero(
                              tag: 'gasto_${gasto.id}',
                              child: Image.file(
                                File(gasto.imagenPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      categoria.icono,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              categoria.icono,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),

                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                gasto.nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Color(categoria.color)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    categoria.icono,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    gasto.categoria,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(categoria.color),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${currencyFormat.format(gasto.precio)} c/u',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${gasto.fechaCreacion.day}/${gasto.fechaCreacion.month}/${gasto.fechaCreacion.year} ${gasto.fechaCreacion.hour.toString().padLeft(2, '0')}:${gasto.fechaCreacion.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        if (gasto.descripcion != null &&
                            gasto.descripcion!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            gasto.descripcion!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Botón eliminar
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 22),
                    color: Colors.red[400],
                    onPressed: onEliminar,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Container(
                height: 1,
                color: Colors.grey[200],
              ),
              const SizedBox(height: 12),

              // Controles de cantidad y subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Controles de cantidad
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF57CC99).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF57CC99).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: onDecrementar,
                          color: const Color(0xFF57CC99),
                          tooltip: 'Disminuir',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${gasto.cantidad}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: onIncrementar,
                          color: const Color(0xFF57CC99),
                          tooltip: 'Aumentar',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Subtotal
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF57CC99),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF57CC99)
                                  .withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          currencyFormat.format(gasto.subtotal),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
