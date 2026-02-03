class Producto {
  int? id;
  String nombre;
  double precio;
  int cantidad;
  String? imagenPath;
  String categoria;
  String? descripcion;
  DateTime fechaCreacion;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    this.cantidad = 1,
    this.imagenPath,
    this.categoria = 'Otros',
    this.descripcion,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  // Convertir de Map a Producto
  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      precio: map['precio'],
      cantidad: map['cantidad'],
      imagenPath: map['imagenPath'],
      categoria: map['categoria'] ?? 'Otros',
      descripcion: map['descripcion'],
      fechaCreacion: map['fechaCreacion'] != null
          ? DateTime.parse(map['fechaCreacion'])
          : DateTime.now(),
    );
  }

  // Convertir de Producto a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
      'imagenPath': imagenPath,
      'categoria': categoria,
      'descripcion': descripcion,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  // Calcular subtotal del producto
  double get subtotal => precio * cantidad;

  // Copiar producto con nuevos valores
  Producto copyWith({
    int? id,
    String? nombre,
    double? precio,
    int? cantidad,
    String? imagenPath,
    String? categoria,
    String? descripcion,
    DateTime? fechaCreacion,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
      imagenPath: imagenPath ?? this.imagenPath,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
