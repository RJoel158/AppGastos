class CategoriaGasto {
  final String nombre;
  final String icono;
  final int color;

  const CategoriaGasto({
    required this.nombre,
    required this.icono,
    required this.color,
  });

  static const List<CategoriaGasto> categorias = [
    CategoriaGasto(nombre: 'Alimentos', icono: '🍔', color: 0xFFFF6B35),
    CategoriaGasto(nombre: 'Transporte', icono: '🚗', color: 0xFF4ECDC4),
    CategoriaGasto(nombre: 'Salud', icono: '💊', color: 0xFFFF6B9D),
    CategoriaGasto(nombre: 'Entretenimiento', icono: '🎮', color: 0xFF95E1D3),
    CategoriaGasto(nombre: 'Educación', icono: '📚', color: 0xFF38A3A5),
    CategoriaGasto(nombre: 'Ropa', icono: '👕', color: 0xFFFFA07A),
    CategoriaGasto(nombre: 'Hogar', icono: '🏠', color: 0xFF80ED99),
    CategoriaGasto(nombre: 'Servicios', icono: '💡', color: 0xFFFFC857),
    CategoriaGasto(nombre: 'Tecnología', icono: '💻', color: 0xFF57CC99),
    CategoriaGasto(nombre: 'Otros', icono: '📦', color: 0xFF9E9E9E),
  ];

  static CategoriaGasto obtenerCategoria(String nombre) {
    try {
      return categorias.firstWhere((c) => c.nombre == nombre);
    } catch (e) {
      return categorias.last; // Retorna "Otros" si no encuentra
    }
  }
}
