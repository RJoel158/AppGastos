import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/producto.dart';
import '../database/database_helper.dart';
import '../models/categoria_gasto.dart';
import 'detalle_gasto_screen.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  List<Producto> _todosLosGastos = [];
  Map<DateTime, List<Producto>> _gastosPorDia = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    setState(() => _isLoading = true);
    final gastos = await _dbHelper.readAllProductos();

    // Organizar gastos por día
    final Map<DateTime, List<Producto>> gastosPorDia = {};
    for (var gasto in gastos) {
      final fecha = DateTime(
        gasto.fechaCreacion.year,
        gasto.fechaCreacion.month,
        gasto.fechaCreacion.day,
      );

      if (gastosPorDia[fecha] == null) {
        gastosPorDia[fecha] = [];
      }
      gastosPorDia[fecha]!.add(gasto);
    }

    setState(() {
      _todosLosGastos = gastos;
      _gastosPorDia = gastosPorDia;
      _isLoading = false;
    });
  }

  List<Producto> _getGastosDelDia(DateTime day) {
    final fecha = DateTime(day.year, day.month, day.day);
    return _gastosPorDia[fecha] ?? [];
  }

  double _getTotalDelDia(DateTime day) {
    final gastos = _getGastosDelDia(day);
    return gastos.fold(0.0, (sum, gasto) => sum + gasto.subtotal);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gastosDelDiaSeleccionado = _getGastosDelDia(_selectedDay);
    final totalDelDia = _getTotalDelDia(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: Color(0xFF80ED99)),
            SizedBox(width: 8),
            Text('Calendario de Gastos',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF80ED99)))
          : Column(
              children: [
                // Calendario
                Card(
                  margin: const EdgeInsets.all(16),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2C3E50),
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: isDark ? Colors.white : const Color(0xFF2C3E50),
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white : const Color(0xFF2C3E50),
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF80ED99).withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF57CC99),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFFFFC857),
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 1,
                      outsideDaysVisible: false,
                    ),
                    eventLoader: (day) => _getGastosDelDia(day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                ),

                // Resumen del día seleccionado
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF57CC99),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM yyyy').format(_selectedDay),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(totalDelDia),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${gastosDelDiaSeleccionado.length} gasto${gastosDelDiaSeleccionado.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Lista de gastos del día
                Expanded(
                  child: gastosDelDiaSeleccionado.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay gastos este día',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: gastosDelDiaSeleccionado.length,
                          itemBuilder: (context, index) {
                            final gasto = gastosDelDiaSeleccionado[index];
                            final categoria = CategoriaGasto.obtenerCategoria(
                                gasto.categoria);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetalleGastoScreen(gasto: gasto),
                                    ),
                                  );
                                },
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Color(categoria.color)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      categoria.icono,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  gasto.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${DateFormat('HH:mm').format(gasto.fechaCreacion)} • ${gasto.categoria}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currencyFormat.format(gasto.subtotal),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(categoria.color),
                                      ),
                                    ),
                                    if (gasto.cantidad > 1)
                                      Text(
                                        'x${gasto.cantidad}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
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
