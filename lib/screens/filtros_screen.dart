import 'package:flutter/material.dart';
import '../models/categoria_gasto.dart';

class FiltrosScreen extends StatefulWidget {
  final String? categoriaSeleccionada;
  final double? precioMin;
  final double? precioMax;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  const FiltrosScreen({
    super.key,
    this.categoriaSeleccionada,
    this.precioMin,
    this.precioMax,
    this.fechaInicio,
    this.fechaFin,
  });

  @override
  State<FiltrosScreen> createState() => _FiltrosScreenState();
}

class _FiltrosScreenState extends State<FiltrosScreen> {
  String? _categoriaSeleccionada;
  double _precioMin = 0;
  double _precioMax = 10000;
  final _precioMinController = TextEditingController();
  final _precioMaxController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _categoriaSeleccionada = widget.categoriaSeleccionada;
    _precioMin = widget.precioMin ?? 0;
    _precioMax = widget.precioMax ?? 10000;
    _precioMinController.text = _precioMin.toStringAsFixed(0);
    _precioMaxController.text = _precioMax.toStringAsFixed(0);
    _fechaInicio = widget.fechaInicio;
    _fechaFin = widget.fechaFin;
  }

  @override
  void dispose() {
    _precioMinController.dispose();
    _precioMaxController.dispose();
    super.dispose();
  }

  void _aplicarFiltros() {
    Navigator.pop(context, {
      'categoria': _categoriaSeleccionada,
      'precioMin': _precioMin,
      'precioMax': _precioMax,
      'fechaInicio': _fechaInicio,
      'fechaFin': _fechaFin,
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _categoriaSeleccionada = null;
      _precioMin = 0;
      _precioMax = 10000;
      _fechaInicio = null;
      _fechaFin = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtros'),
        actions: [
          TextButton(
            onPressed: _limpiarFiltros,
            child: const Text('Limpiar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Categoría
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.category, color: Color(0xFF80ED99)),
                      const SizedBox(width: 8),
                      Text(
                        'Categoría',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Todas'),
                        selected: _categoriaSeleccionada == null,
                        onSelected: (selected) {
                          setState(() => _categoriaSeleccionada = null);
                        },
                      ),
                      ...CategoriaGasto.categorias.map((cat) {
                        return FilterChip(
                          avatar: Text(cat.icono),
                          label: Text(cat.nombre),
                          selected: _categoriaSeleccionada == cat.nombre,
                          onSelected: (selected) {
                            setState(() {
                              _categoriaSeleccionada =
                                  selected ? cat.nombre : null;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Rango de precio
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_money, color: Color(0xFFFFC857)),
                      const SizedBox(width: 8),
                      Text(
                        'Rango de precio',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _precioMinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Mínimo',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            final precio = double.tryParse(value);
                            if (precio != null &&
                                precio >= 0 &&
                                precio <= _precioMax) {
                              setState(() => _precioMin = precio);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _precioMaxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Máximo',
                            prefixText: '\$',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            final precio = double.tryParse(value);
                            if (precio != null && precio >= _precioMin) {
                              setState(() => _precioMax = precio);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: RangeValues(_precioMin, _precioMax),
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    activeColor: const Color(0xFF80ED99),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _precioMin = values.start;
                        _precioMax = values.end;
                        _precioMinController.text =
                            _precioMin.toStringAsFixed(0);
                        _precioMaxController.text =
                            _precioMax.toStringAsFixed(0);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Rango de fechas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFFFF6B35)),
                      const SizedBox(width: 8),
                      Text(
                        'Rango de fechas',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final fecha = await showDatePicker(
                              context: context,
                              initialDate: _fechaInicio ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (fecha != null) {
                              setState(() => _fechaInicio = fecha);
                            }
                          },
                          icon: const Icon(Icons.event),
                          label: Text(
                            _fechaInicio == null
                                ? 'Desde'
                                : '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final fecha = await showDatePicker(
                              context: context,
                              initialDate: _fechaFin ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (fecha != null) {
                              setState(() => _fechaFin = fecha);
                            }
                          },
                          icon: const Icon(Icons.event),
                          label: Text(
                            _fechaFin == null
                                ? 'Hasta'
                                : '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _aplicarFiltros,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF80ED99),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child:
                const Text('Aplicar filtros', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
