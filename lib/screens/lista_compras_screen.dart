import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';
import '../database/database_helper.dart';
import '../widgets/producto_card.dart';
import '../widgets/agregar_producto_dialog.dart';

class ListaComprasScreen extends StatefulWidget {
  const ListaComprasScreen({super.key});

  @override
  State<ListaComprasScreen> createState() => _ListaComprasScreenState();
}

class _ListaComprasScreenState extends State<ListaComprasScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Producto> _productos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() => _isLoading = true);
    final productos = await _dbHelper.readAllProductos();
    setState(() {
      _productos = productos;
      _isLoading = false;
    });
  }

  double get _totalCompra {
    return _productos.fold(0.0, (sum, producto) => sum + producto.subtotal);
  }

  Future<void> _mostrarDialogoAgregar() async {
    final resultado = await showDialog<Producto>(
      context: context,
      builder: (context) => const AgregarProductoDialog(),
    );

    if (resultado != null) {
      await _dbHelper.create(resultado);
      _cargarProductos();
    }
  }

  Future<void> _actualizarCantidad(Producto producto, int nuevaCantidad) async {
    if (nuevaCantidad <= 0) {
      await _eliminarProducto(producto);
      return;
    }

    final productoActualizado = producto.copyWith(cantidad: nuevaCantidad);
    await _dbHelper.update(productoActualizado);
    _cargarProductos();
  }

  Future<void> _eliminarProducto(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Deseas eliminar "${producto.nombre}" de la lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && producto.id != null) {
      await _dbHelper.delete(producto.id!);
      _cargarProductos();
    }
  }

  Future<void> _limpiarLista() async {
    if (_productos.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar lista'),
        content:
            const Text('¿Deseas eliminar todos los productos de la lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _dbHelper.deleteAll();
      _cargarProductos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista de Compras',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_productos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Limpiar lista',
              onPressed: _limpiarLista,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Total de la compra
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total de la compra',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(_totalCompra),
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_productos.length} producto${_productos.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),

                // Lista de productos
                Expanded(
                  child: _productos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 100,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay productos',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toca el botón + para agregar',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _productos.length,
                          itemBuilder: (context, index) {
                            final producto = _productos[index];
                            return ProductoCard(
                              producto: producto,
                              onIncrementar: () => _actualizarCantidad(
                                producto,
                                producto.cantidad + 1,
                              ),
                              onDecrementar: () => _actualizarCantidad(
                                producto,
                                producto.cantidad - 1,
                              ),
                              onEliminar: () => _eliminarProducto(producto),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoAgregar,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}
