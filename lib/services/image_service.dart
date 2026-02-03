import 'dart:io';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class ImageService {
  static const String albumName = 'AppCompras';
  static const String _keyMigracionCompletada = 'imagenes_migradas_v1';

  /// Guarda una imagen en la galería del dispositivo
  /// Retorna el path de la imagen guardada o null si hay error
  static Future<String?> guardarEnGaleria(String imagePath) async {
    try {
      // Verificar que el archivo existe
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return null;
      }

      // Guardar en la galería usando Gal (maneja permisos automáticamente)
      await Gal.putImage(imagePath, album: albumName);

      // Retornar el path original
      return imagePath;
    } catch (e) {
      print('Error al guardar imagen en galería: $e');
      return null;
    }
  }

  /// Verifica si se tienen los permisos necesarios
  static Future<bool> tienePermisos() async {
    try {
      return await Gal.hasAccess();
    } catch (e) {
      print('Error al verificar permisos: $e');
      return false;
    }
  }

  /// Solicita los permisos necesarios para guardar imágenes
  static Future<bool> solicitarPermisos() async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (hasAccess) {
        return true;
      }
      return await Gal.requestAccess();
    } catch (e) {
      print('Error al solicitar permisos: $e');
      return false;
    }
  }

  /// Migra todas las imágenes existentes a la galería (solo se ejecuta una vez)
  static Future<void> migrarImagenesExistentes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar si ya se realizó la migración
      final yaMigrado = prefs.getBool(_keyMigracionCompletada) ?? false;
      if (yaMigrado) {
        print('Las imágenes ya fueron migradas anteriormente');
        return;
      }

      // Solicitar permisos
      final hasPermission = await solicitarPermisos();
      if (!hasPermission) {
        print('No se otorgaron permisos para migrar imágenes');
        return;
      }

      // Obtener todos los productos con imágenes
      final db = DatabaseHelper.instance;
      final productos = await db.readAllProductos();

      int exitosas = 0;
      int fallidas = 0;

      for (final producto in productos) {
        if (producto.imagenPath != null && producto.imagenPath!.isNotEmpty) {
          final file = File(producto.imagenPath!);

          // Verificar si el archivo existe
          if (await file.exists()) {
            final resultado = await guardarEnGaleria(producto.imagenPath!);
            if (resultado != null) {
              exitosas++;
              print('✅ Imagen migrada: ${path.basename(producto.imagenPath!)}');
            } else {
              fallidas++;
              print(
                  '⚠️ No se pudo migrar: ${path.basename(producto.imagenPath!)}');
            }
          } else {
            fallidas++;
            print('⚠️ Archivo no encontrado: ${producto.imagenPath}');
          }
        }
      }

      // Marcar la migración como completada
      await prefs.setBool(_keyMigracionCompletada, true);

      print('🎉 Migración completada: $exitosas exitosas, $fallidas fallidas');
    } catch (e) {
      print('Error durante la migración de imágenes: $e');
    }
  }

  /// Resetea el flag de migración (solo para desarrollo/testing)
  static Future<void> resetearMigracion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMigracionCompletada);
    print('Flag de migración reseteado');
  }
}
