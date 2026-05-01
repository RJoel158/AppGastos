import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../database/database_helper.dart';
import 'package:path_provider/path_provider.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({Key? key}) : super(key: key);

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _exportando = false;
  bool _importando = false;

  Future<void> _exportarDatos() async {
    setState(() => _exportando = true);

    try {
      final datos = await DatabaseHelper.instance.exportarDatos();

      // Guardar en archivo temporal
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}/backup_gastos_$timestamp.json');
      await file.writeAsString(datos);

      // Compartir archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Backup Control de Gastos',
        text: 'Respaldo de datos de Control de Gastos',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos exportados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _exportando = false);
    }
  }

  Future<void> _importarDatos() async {
    setState(() => _importando = true);

    try {
      // Seleccionar archivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contenido = await file.readAsString();

        // Confirmar antes de importar
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Confirmar Importación'),
            content: const Text(
              '¿Estás seguro? Esta acción reemplazará todos tus datos actuales con los del archivo de respaldo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Importar'),
              ),
            ],
          ),
        );

        if (confirmar == true) {
          final exito = await DatabaseHelper.instance.importarDatos(contenido);

          if (mounted) {
            if (exito) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Datos importados correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
              // Reiniciar la app para reflejar cambios
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Error: Archivo inválido'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _importando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Configuración'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '💾 Respaldo y Recuperación de Datos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.blue),
            title: const Text('Exportar Datos (Guardar)'),
            subtitle: const Text('Crear archivo .json con todos tus gastos'),
            trailing: _exportando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_ios),
            onTap: _exportando ? null : _exportarDatos,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.orange),
            title: const Text('Importar Datos (Recuperar)'),
            subtitle: const Text('Restaurar gastos desde archivo .json'),
            trailing: _importando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_ios),
            onTap: _importando ? null : _importarDatos,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  color: Colors.blue,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Información',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '💡 Exporta tus datos regularmente para no perderlos al desinstalar la app.\n\n'
                          '📱 El archivo de respaldo (.json) se puede compartir por WhatsApp, email, Drive, etc.\n\n'
                          '🔄 Para restaurar tus datos en otro dispositivo, simplemente importa el archivo.\n\n'
                          '📄 El PDF es solo para visualización. Para recuperar datos usa el archivo .json\n\n'
                          '📸 Toca el ícono de cada gasto para agregar una foto desde tu galería',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.orange.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              '⚠️ Importante',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cuando desinstalas la app, TODOS los datos se borran automáticamente. '
                          'Asegúrate de exportar tus datos ANTES de desinstalar.',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
