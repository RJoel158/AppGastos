import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/producto.dart';
import '../database/database_helper.dart';

class VincularImagenesScreen extends StatefulWidget {
  const VincularImagenesScreen({Key? key}) : super(key: key);

  @override
  State<VincularImagenesScreen> createState() => _VincularImagenesScreenState();
}

class _VincularImagenesScreenState extends State<VincularImagenesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker();
  List<Producto> _gastosSinImagen = [];
  Map<int, String> _vinculacionesPendientes = {};
  bool _cargando = true;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarGastosSinImagen();
  }

  Future<void> _cargarGastosSinImagen() async {
    setState(() => _cargando = true);

    try {
      final todosLosGastos = await _dbHelper.readAllProductos();
      _gastosSinImagen = todosLosGastos
          .where((g) => g.imagenPath == null || g.imagenPath!.isEmpty)
          .toList()
        ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    } catch (e) {
      print('Error al cargar datos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarImagen(Producto gasto) async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (imagen != null) {
        setState(() {
          _vinculacionesPendientes[gasto.id!] = imagen.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _aplicarVinculaciones() async {
    if (_vinculacionesPendientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay vinculaciones pendientes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _procesando = true);

    int exitosas = 0;
    int fallidas = 0;

    try {
      for (var entry in _vinculacionesPendientes.entries) {
        final gastoId = entry.key;
        final imagenPath = entry.value;

        final gasto = _gastosSinImagen.firstWhere((g) => g.id == gastoId);
        final gastoActualizado = gasto.copyWith(imagenPath: imagenPath);

        final resultado = await _dbHelper.update(gastoActualizado);
        if (resultado > 0) {
          exitosas++;
        } else {
          fallidas++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ $exitosas vinculaciones exitosas${fallidas > 0 ? ", $fallidas fallidas" : ""}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        if (exitosas > 0) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aplicar vinculaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔗 Vincular Imágenes'),
        actions: [
          if (_vinculacionesPendientes.isNotEmpty)
            TextButton.icon(
              onPressed: _procesando ? null : _aplicarVinculaciones,
              icon: _procesando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check, color: Colors.white),
              label: Text(
                'Aplicar (${_vinculacionesPendientes.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _gastosSinImagen.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          '¡Todos los gastos tienen imágenes!',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Info card
                    Card(
                      margin: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Vincular imágenes manualmente',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Se encontraron ${_gastosSinImagen.length} gastos sin imagen.\n\n'
                              'Toca "Vincular" en cada gasto para seleccionar una imagen de tu galería.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Lista de gastos
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _gastosSinImagen.length,
                        itemBuilder: (context, index) {
                          final gasto = _gastosSinImagen[index];
                          final imagenVinculada =
                              _vinculacionesPendientes[gasto.id];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Info del gasto
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              gasto.nombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dateFormat
                                                  .format(gasto.fechaCreacion),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              '\$${gasto.subtotal.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Miniatura de imagen vinculada
                                      if (imagenVinculada != null)
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.green,
                                              width: 2,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Image.file(
                                              File(imagenVinculada),
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stack) {
                                                return const Icon(
                                                    Icons.broken_image);
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Botones
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (imagenVinculada != null)
                                        TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _vinculacionesPendientes
                                                  .remove(gasto.id);
                                            });
                                          },
                                          icon:
                                              const Icon(Icons.close, size: 16),
                                          label: const Text('Quitar'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _seleccionarImagen(gasto),
                                        icon: Icon(
                                          imagenVinculada != null
                                              ? Icons.edit
                                              : Icons.add_photo_alternate,
                                          size: 16,
                                        ),
                                        label: Text(imagenVinculada != null
                                            ? 'Cambiar'
                                            : 'Vincular'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
