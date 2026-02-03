import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/producto.dart';
import '../models/categoria_gasto.dart';
import '../services/image_service.dart';

class AgregarGastoDialog extends StatefulWidget {
  final Producto? gasto;

  const AgregarGastoDialog({super.key, this.gasto});

  @override
  State<AgregarGastoDialog> createState() => _AgregarGastoDialogState();
}

class _AgregarGastoDialogState extends State<AgregarGastoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _descripcionController = TextEditingController();

  String _categoriaSeleccionada = 'Otros';
  String? _imagenPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.gasto != null) {
      _nombreController.text = widget.gasto!.nombre;
      _precioController.text = widget.gasto!.precio.toString();
      _cantidadController.text = widget.gasto!.cantidad.toString();
      _descripcionController.text = widget.gasto!.descripcion ?? '';
      _categoriaSeleccionada = widget.gasto!.categoria;
      _imagenPath = widget.gasto!.imagenPath;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _cantidadController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        // Guardar la imagen en la galería
        final savedPath = await ImageService.guardarEnGaleria(image.path);

        if (savedPath != null && mounted) {
          setState(() {
            _imagenPath = image.path;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Foto guardada en la galería AppCompras'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF57CC99),
            ),
          );
        } else if (mounted) {
          setState(() {
            _imagenPath = image.path;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '⚠️ Foto guardada solo en la app. Verifica los permisos de almacenamiento.'),
              duration: Duration(seconds: 3),
              backgroundColor: Color(0xFFFFC857),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _mostrarOpcionesImagen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF80ED99).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF57CC99)),
                ),
                title: const Text('Tomar foto',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarImagen(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC857).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.photo_library, color: Color(0xFFFFC857)),
                ),
                title: const Text('Elegir de galería',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarImagen(ImageSource.gallery);
                },
              ),
              if (_imagenPath != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Eliminar foto',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    setState(() => _imagenPath = null);
                    Navigator.pop(context);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final gasto = Producto(
        id: widget.gasto?.id,
        nombre: _nombreController.text.trim(),
        precio: double.parse(_precioController.text.trim()),
        cantidad: int.parse(_cantidadController.text.trim()),
        categoria: _categoriaSeleccionada,
        imagenPath: _imagenPath,
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
      );
      Navigator.pop(context, gasto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoria = CategoriaGasto.obtenerCategoria(_categoriaSeleccionada);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final fieldBgColor =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado fijo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF57CC99),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF57CC99).withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.gasto == null ? 'Nuevo Gasto' : 'Editar Gasto',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Imagen
                      Center(
                        child: GestureDetector(
                          onTap: _mostrarOpcionesImagen,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: fieldBgColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF80ED99)
                                    .withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.3 : 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: _imagenPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      File(_imagenPath!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo,
                                          size: 38, color: subtextColor),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Foto',
                                        style: TextStyle(
                                          color: subtextColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Categoría
                      Text(
                        'Categoría',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: subtextColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: fieldBgColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _categoriaSeleccionada,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            borderRadius: BorderRadius.circular(12),
                            items: CategoriaGasto.categorias.map((cat) {
                              return DropdownMenuItem(
                                value: cat.nombre,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: Color(cat.color)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(cat.icono,
                                          style: const TextStyle(fontSize: 18)),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      cat.nombre,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _categoriaSeleccionada = value!);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      TextFormField(
                        controller: _nombreController,
                        style: TextStyle(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Nombre del gasto',
                          labelStyle: TextStyle(color: subtextColor),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              categoria.icono,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Precio y Cantidad
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _precioController,
                              style: TextStyle(fontSize: 14, color: textColor),
                              decoration: InputDecoration(
                                labelText: 'Precio',
                                labelStyle: TextStyle(color: subtextColor),
                                prefixIcon: const Icon(Icons.attach_money,
                                    color: Color(0xFF57CC99), size: 20),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Requerido';
                                }
                                final precio = double.tryParse(value.trim());
                                if (precio == null || precio <= 0) {
                                  return 'Inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _cantidadController,
                              style: TextStyle(fontSize: 14, color: textColor),
                              decoration: InputDecoration(
                                labelText: 'Cant.',
                                labelStyle: TextStyle(color: subtextColor),
                                prefixIcon: const Icon(Icons.numbers,
                                    color: Color(0xFFFFC857), size: 20),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Req.';
                                }
                                final cantidad = int.tryParse(value.trim());
                                if (cantidad == null || cantidad <= 0) {
                                  return 'Inv.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Descripción
                      TextFormField(
                        controller: _descripcionController,
                        style: TextStyle(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Descripción (opcional)',
                          labelStyle: TextStyle(color: subtextColor),
                          prefixIcon: const Icon(Icons.description_outlined,
                              color: Color(0xFF95E1D3), size: 20),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 20),

                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: subtextColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: _guardar,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF57CC99),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text(
                                'Guardar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
