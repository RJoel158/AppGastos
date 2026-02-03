import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/producto.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const String _keyProductos = 'productos';
  static int _nextId = 1;

  DatabaseHelper._init();

  // Crear un producto
  Future<Producto> create(Producto producto) async {
    final prefs = await SharedPreferences.getInstance();
    final productos = await readAllProductos();

    final nuevoProducto = producto.copyWith(id: _nextId++);
    productos.add(nuevoProducto);

    await _saveProductos(prefs, productos);
    return nuevoProducto;
  }

  // Leer un producto por ID
  Future<Producto?> readProducto(int id) async {
    final productos = await readAllProductos();
    try {
      return productos.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Leer todos los productos
  Future<List<Producto>> readAllProductos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productosJson = prefs.getString(_keyProductos);

    if (productosJson == null || productosJson.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(productosJson);
    final productos = decoded
        .map((json) => Producto.fromMap(json as Map<String, dynamic>))
        .toList();

    // Actualizar _nextId para que sea mayor que el último ID usado
    if (productos.isNotEmpty) {
      final maxId =
          productos.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b);
      _nextId = maxId + 1;
    }

    return productos;
  }

  // Actualizar un producto
  Future<int> update(Producto producto) async {
    final prefs = await SharedPreferences.getInstance();
    final productos = await readAllProductos();

    final index = productos.indexWhere((p) => p.id == producto.id);
    if (index != -1) {
      productos[index] = producto;
      await _saveProductos(prefs, productos);
      return 1;
    }
    return 0;
  }

  // Eliminar un producto
  Future<int> delete(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final productos = await readAllProductos();

    final lengthBefore = productos.length;
    productos.removeWhere((p) => p.id == id);

    if (productos.length < lengthBefore) {
      await _saveProductos(prefs, productos);
      return 1;
    }
    return 0;
  }

  // Eliminar todos los productos
  Future<int> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    final productos = await readAllProductos();
    final count = productos.length;

    await prefs.remove(_keyProductos);
    _nextId = 1;

    return count;
  }

  // Guardar productos en SharedPreferences
  Future<void> _saveProductos(
      SharedPreferences prefs, List<Producto> productos) async {
    final List<Map<String, dynamic>> productosMap =
        productos.map((p) => p.toMap()).toList();
    final String productosJson = jsonEncode(productosMap);
    await prefs.setString(_keyProductos, productosJson);
  }

  // Cerrar la base de datos (no necesario para SharedPreferences, pero mantenemos la interfaz)
  Future close() async {
    // No hay nada que cerrar con SharedPreferences
  }
}
