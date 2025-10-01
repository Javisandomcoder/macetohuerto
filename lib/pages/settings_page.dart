import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';
import '../providers/settings_provider.dart';
import '../providers/plant_provider.dart';
import '../services/notification_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final DatabaseService _db = DatabaseService();
  bool _exporting = false;
  bool _importing = false;

  Future<void> _exportData() async {
    setState(() => _exporting = true);

    try {
      final data = await _db.exportData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/macetohuerto_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Backup de Macetohuerto',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos exportados correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _importData() async {
    // Note: Importing requires file_picker package
    // For now, show a simple instruction dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar datos'),
        content: const Text(
          'Para importar datos, necesitas un archivo de backup JSON.\n\n'
          'Esta funcionalidad estará disponible próximamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Datos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Exportar datos'),
            subtitle: const Text('Crear copia de seguridad'),
            trailing: _exporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _exporting ? null : _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Importar datos'),
            subtitle: const Text('Restaurar desde backup'),
            trailing: _importing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _importing ? null : _importData,
          ),
          const Divider(),
          const ListTile(
            title: Text(
              'Riego',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(settingsProvider);
              return ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: const Text('Modo estacional'),
                subtitle: Text(settings.seasonMode.label),
                trailing: DropdownButton<SeasonMode>(
                  value: settings.seasonMode,
                  underline: const SizedBox(),
                  items: SeasonMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Row(
                        children: [
                          Icon(
                            mode == SeasonMode.summer
                                ? Icons.wb_sunny
                                : Icons.ac_unit,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(mode.label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newMode) async {
                    if (newMode != null && newMode != settings.seasonMode) {
                      await ref.read(settingsProvider.notifier).setSeasonMode(newMode);

                      // Reprogramar todas las notificaciones con el nuevo multiplicador
                      final plantsState = ref.read(plantsProvider);
                      plantsState.whenData((plants) {
                        final updatedSettings = ref.read(settingsProvider);
                        final notificationService = NotificationService();
                        for (final plant in plants) {
                          if (plant.reminderEnabled && !plant.reminderPaused) {
                            notificationService.scheduleNextForPlant(
                              plant: plant,
                              globallyPaused: updatedSettings.remindersPaused,
                              pausedUntil: updatedSettings.pausedUntil,
                              seasonMultiplier: updatedSettings.seasonMode.multiplier,
                            );
                          }
                        }
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              newMode == SeasonMode.winter
                                  ? 'Modo invierno: los intervalos se amplían un 50%'
                                  : 'Modo verano: intervalos normales',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '💡 En invierno las plantas necesitan menos agua. El modo invierno multiplica los intervalos x1.5 automáticamente.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text(
              'Acerca de',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versión'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
