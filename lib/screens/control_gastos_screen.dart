import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';
import '../models/categoria_gasto.dart';
import '../database/database_helper.dart';
import '../widgets/gasto_card.dart';
import '../widgets/agregar_gasto_dialog.dart';
import '../main.dart';
import 'filtros_screen.dart';
import 'detalle_gasto_screen.dart';
import 'calendario_screen.dart';
import '../services/pdf_service.dart';

class ControlGastosScreen extends StatefulWidget {
  const ControlGastosScreen({super.key});

  @override
  State<ControlGastosScreen> createState() => _ControlGastosScreenState();
}

class _ControlGastosScreenState extends State<ControlGastosScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Producto> _gastos = [];
  List<Producto> _gastosFiltrados = [];
  bool _isLoading = true;

  String? _categoriaFiltro;
  double? _precioMinFiltro;
  double? _precioMaxFiltro;
  DateTime? _fechaInicioFiltro;
  DateTime? _fechaFinFiltro;

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    setState(() => _isLoading = true);
    final gastos = await _dbHelper.readAllProductos();
    setState(() {
      _gastos = gastos;
      _aplicarFiltrosLocales();
      _isLoading = false;
    });
  }

  void _aplicarFiltrosLocales() {
    _gastosFiltrados = _gastos.where((gasto) {
      bool cumpleFiltro = true;

      if (_categoriaFiltro != null && gasto.categoria != _categoriaFiltro) {
        cumpleFiltro = false;
      }

      if (_precioMinFiltro != null && gasto.precio < _precioMinFiltro!) {
        cumpleFiltro = false;
      }

      if (_precioMaxFiltro != null && gasto.precio > _precioMaxFiltro!) {
        cumpleFiltro = false;
      }

      // Filtros de fecha
      if (_fechaInicioFiltro != null) {
        final fechaGasto = DateTime(gasto.fechaCreacion.year,
            gasto.fechaCreacion.month, gasto.fechaCreacion.day);
        final fechaInicio = DateTime(_fechaInicioFiltro!.year,
            _fechaInicioFiltro!.month, _fechaInicioFiltro!.day);
        if (fechaGasto.isBefore(fechaInicio)) {
          cumpleFiltro = false;
        }
      }

      if (_fechaFinFiltro != null) {
        final fechaGasto = DateTime(gasto.fechaCreacion.year,
            gasto.fechaCreacion.month, gasto.fechaCreacion.day);
        final fechaFin = DateTime(_fechaFinFiltro!.year, _fechaFinFiltro!.month,
            _fechaFinFiltro!.day);
        if (fechaGasto.isAfter(fechaFin)) {
          cumpleFiltro = false;
        }
      }

      return cumpleFiltro;
    }).toList();

    // Ordenar por fecha de creación: más recientes primero
    _gastosFiltrados.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
  }

  double get _totalGastos {
    return _gastosFiltrados.fold(0.0, (sum, gasto) => sum + gasto.subtotal);
  }

  Map<String, double> get _gastosPorCategoria {
    final Map<String, double> gastos = {};
    for (var gasto in _gastosFiltrados) {
      gastos[gasto.categoria] = (gastos[gasto.categoria] ?? 0) + gasto.subtotal;
    }
    return gastos;
  }

  Future<void> _mostrarDialogoAgregar([Producto? gasto]) async {
    final resultado = await showDialog<Producto>(
      context: context,
      builder: (context) => AgregarGastoDialog(gasto: gasto),
    );

    if (resultado != null) {
      if (gasto == null) {
        await _dbHelper.create(resultado);
      } else {
        await _dbHelper.update(resultado);
      }
      _cargarGastos();
    }
  }

  Future<void> _actualizarCantidad(Producto gasto, int nuevaCantidad) async {
    if (nuevaCantidad <= 0) {
      await _eliminarGasto(gasto);
      return;
    }

    final gastoActualizado = gasto.copyWith(cantidad: nuevaCantidad);
    await _dbHelper.update(gastoActualizado);
    _cargarGastos();
  }

  Future<void> _eliminarGasto(Producto gasto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Deseas eliminar "${gasto.nombre}" de la lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && gasto.id != null) {
      await _dbHelper.delete(gasto.id!);
      _cargarGastos();
    }
  }

  Future<void> _limpiarLista() async {
    if (_gastos.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar todos los gastos'),
        content: const Text(
            '¿Deseas eliminar todos los gastos? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _dbHelper.deleteAll();
      _cargarGastos();
    }
  }

  Future<void> _mostrarFiltros() async {
    final resultado = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FiltrosScreen(
          categoriaSeleccionada: _categoriaFiltro,
          precioMin: _precioMinFiltro,
          precioMax: _precioMaxFiltro,
          fechaInicio: _fechaInicioFiltro,
          fechaFin: _fechaFinFiltro,
        ),
      ),
    );

    if (resultado != null) {
      setState(() {
        _categoriaFiltro = resultado['categoria'];
        _precioMinFiltro = resultado['precioMin'];
        _precioMaxFiltro = resultado['precioMax'];
        _fechaInicioFiltro = resultado['fechaInicio'];
        _fechaFinFiltro = resultado['fechaFin'];
        _aplicarFiltrosLocales();
      });
    }
  }

  Future<void> _generarPDF() async {
    if (_gastosFiltrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay gastos para generar el reporte'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await PdfService.generarReporteGastos(
        gastos: _gastosFiltrados,
        categoriaFiltro: _categoriaFiltro,
        precioMin: _precioMinFiltro,
        precioMax: _precioMaxFiltro,
        fechaInicio: _fechaInicioFiltro,
        fechaFin: _fechaFinFiltro,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final hasFiltros = _categoriaFiltro != null ||
        (_precioMinFiltro != null && _precioMinFiltro! > 0) ||
        (_precioMaxFiltro != null && _precioMaxFiltro! < 10000);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Gastos',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalendarioScreen(),
                ),
              );
            },
            tooltip: 'Calendario',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Más opciones',
            onSelected: (value) {
              switch (value) {
                case 'tema':
                  MyApp.of(context).toggleTheme();
                  break;
                case 'filtros':
                  _mostrarFiltros();
                  break;
                case 'pdf':
                  _generarPDF();
                  break;
                case 'limpiar':
                  _limpiarLista();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'tema',
                child: Row(
                  children: [
                    Icon(
                      Theme.of(context).brightness == Brightness.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'Modo claro'
                          : 'Modo oscuro',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'filtros',
                child: Row(
                  children: [
                    Badge(
                      isLabelVisible: hasFiltros,
                      backgroundColor: const Color(0xFFFF6B35),
                      child: const Icon(Icons.filter_list, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Filtros'),
                  ],
                ),
              ),
              if (_gastosFiltrados.isNotEmpty)
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, size: 20, color: Colors.green),
                      SizedBox(width: 12),
                      Text('Generar PDF'),
                    ],
                  ),
                ),
              if (_gastos.isNotEmpty)
                const PopupMenuItem(
                  value: 'limpiar',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Limpiar todo', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF80ED99)))
          : Column(
              children: [
                // Total de gastos
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF57CC99),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF80ED99).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Total de gastos',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(_totalGastos),
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 36,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_gastosFiltrados.length} registro${_gastosFiltrados.length != 1 ? 's' : ''}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Resumen por categorías
                if (_gastosPorCategoria.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 58,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _gastosPorCategoria.length,
                        itemBuilder: (context, index) {
                          final categoria =
                              _gastosPorCategoria.keys.elementAt(index);
                          final monto = _gastosPorCategoria[categoria]!;
                          final cat =
                              CategoriaGasto.obtenerCategoria(categoria);

                          return Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Color(cat.color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(cat.color)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(cat.icono,
                                    style: const TextStyle(fontSize: 16)),
                                Text(
                                  categoria,
                                  style: const TextStyle(fontSize: 9),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  currencyFormat.format(monto),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(cat.color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Lista de gastos
                Expanded(
                  child: _gastosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasFiltros
                                    ? Icons.search_off
                                    : Icons.receipt_long_outlined,
                                size: 100,
                                color: const Color(0xFF80ED99)
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                hasFiltros
                                    ? 'Sin resultados'
                                    : 'No hay gastos registrados',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasFiltros
                                    ? 'Intenta ajustar los filtros'
                                    : 'Toca el botón + para agregar',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _gastosFiltrados.length,
                          itemBuilder: (context, index) {
                            final gasto = _gastosFiltrados[index];
                            return GastoCard(
                              gasto: gasto,
                              onIncrementar: () => _actualizarCantidad(
                                  gasto, gasto.cantidad + 1),
                              onDecrementar: () => _actualizarCantidad(
                                  gasto, gasto.cantidad - 1),
                              onEliminar: () => _eliminarGasto(gasto),
                              onEditar: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetalleGastoScreen(gasto: gasto),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoAgregar(),
        backgroundColor: const Color(0xFF80ED99),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo gasto', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
