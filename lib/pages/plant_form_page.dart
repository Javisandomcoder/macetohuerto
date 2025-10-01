import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macetohuerto/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/plant.dart';
import '../models/care_log.dart';
import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
import '../utils/input_formatters.dart';

class PlantFormPage extends ConsumerStatefulWidget {
  final Plant? initial;
  const PlantFormPage({super.key, this.initial});

  @override
  ConsumerState<PlantFormPage> createState() => _PlantFormPageState();
}

class _PlantFormPageState extends ConsumerState<PlantFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _speciesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _picker = ImagePicker();
  DateTime? _plantedAt;
  bool _reminderEnabled = false;
  bool _reminderPaused = false;
  int _intervalDays = 2;
  TimeOfDay _timeOfDay = const TimeOfDay(hour: 9, minute: 0);
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p != null) {
      _nameCtrl.text = p.name;
      _speciesCtrl.text = p.species ?? '';
      _locationCtrl.text = p.location ?? '';
      _notesCtrl.text = p.notes ?? '';
      _plantedAt = p.plantedAt;
      _reminderEnabled = p.reminderEnabled;
      _reminderPaused = p.reminderPaused;
      _intervalDays = p.wateringIntervalDays ?? _intervalDays;
      if (p.wateringTime != null && p.wateringTime!.contains(':')) {
        final parts = p.wateringTime!.split(':');
        final h = int.tryParse(parts[0]) ?? 9;
        final m = int.tryParse(parts[1]) ?? 0;
        _timeOfDay = TimeOfDay(hour: h, minute: m);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _speciesCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _capturedImage = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar imagen: $e')),
        );
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_capturedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Eliminar foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _capturedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? l10n.plantEdit : l10n.plantNew)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image preview/capture
            Center(
              child: GestureDetector(
                onTap: _showImageOptions,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: _capturedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(_capturedImage!.path),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Añadir foto',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(Opcional)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: const [CapitalizeFirstInputFormatter()],
              decoration: InputDecoration(labelText: l10n.nameLabel),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _speciesCtrl,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: const [CapitalizeFirstInputFormatter()],
              decoration: InputDecoration(labelText: l10n.speciesLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationCtrl,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: const [CapitalizeFirstInputFormatter()],
              decoration: InputDecoration(labelText: l10n.locationLabel),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(_plantedAt == null
                      ? '${l10n.plantedLabel}: —'
                      : '${l10n.plantedLabel}: ${DateFormat('dd/MM/yyyy').format(_plantedAt!)}'),
                ),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _plantedAt ?? now,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (picked != null) {
                      setState(() => _plantedAt = picked);
                    }
                  },
                  child: Text(l10n.pickDate),
                )
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: const [CapitalizeFirstInputFormatter()],
              decoration: InputDecoration(labelText: l10n.notesLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text('Recordatorio de riego',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _reminderEnabled,
              title: const Text('Activar recordatorio'),
              onChanged: (v) => setState(() => _reminderEnabled = v),
            ),
            if (_reminderEnabled) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _intervalDays,
                      decoration:
                          const InputDecoration(labelText: 'Cada (días)'),
                      items: const [1, 2, 3, 4, 5, 7, 10, 14, 21, 30]
                          .map((d) =>
                              DropdownMenuItem(value: d, child: Text('$d')))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _intervalDays = v ?? _intervalDays),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                            context: context, initialTime: _timeOfDay);
                        if (picked != null) setState(() => _timeOfDay = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Hora'),
                        child: Text(_timeOfDay.format(context)),
                      ),
                    ),
                  )
                ],
              ),
              SwitchListTile(
                value: _reminderPaused,
                title: const Text('Pausar recordatorio (planta)'),
                onChanged: (v) => setState(() => _reminderPaused = v),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                // Haptic feedback on action confirmation
                HapticFeedback.mediumImpact();
                if (!_formKey.currentState!.validate()) return;
                final id = widget.initial?.id ?? const Uuid().v4();
                final plant = Plant(
                  id: id,
                  name: _nameCtrl.text.trim(),
                  species: _speciesCtrl.text.trim().isEmpty
                      ? null
                      : _speciesCtrl.text.trim(),
                  location: _locationCtrl.text.trim().isEmpty
                      ? null
                      : _locationCtrl.text.trim(),
                  plantedAt: _plantedAt,
                  notes: _notesCtrl.text.trim().isEmpty
                      ? null
                      : _notesCtrl.text.trim(),
                  reminderEnabled: _reminderEnabled,
                  reminderPaused: _reminderPaused,
                  wateringIntervalDays: _reminderEnabled ? _intervalDays : null,
                  wateringTime: _reminderEnabled
                      ? '${_timeOfDay.hour.toString().padLeft(2, '0')}:${_timeOfDay.minute.toString().padLeft(2, '0')}'
                      : null,
                  lastWateredAt: widget.initial?.lastWateredAt,
                );
                if (widget.initial == null) {
                  await ref.read(plantsProvider.notifier).add(plant);
                } else {
                  await ref.read(plantsProvider.notifier).update(plant);
                }

                // Save captured image if exists
                if (_capturedImage != null) {
                  try {
                    final appDir = await getApplicationDocumentsDirectory();
                    final imagesDir = Directory(path.join(appDir.path, 'plant_images'));
                    if (!await imagesDir.exists()) {
                      await imagesDir.create(recursive: true);
                    }

                    final fileName = '${const Uuid().v4()}${path.extension(_capturedImage!.path)}';
                    final savedPath = path.join(imagesDir.path, fileName);
                    await File(_capturedImage!.path).copy(savedPath);

                    // Save to database
                    final image = PlantImage(
                      plantId: plant.id,
                      imagePath: savedPath,
                      takenAt: DateTime.now(),
                    );

                    await DatabaseService().insertPlantImage(image);
                  } catch (e) {
                    debugPrint('Failed to save plant image: $e');
                  }
                }

                // schedule/cancel
                final settings = ref.read(settingsProvider);
                final notifier = NotificationService();
                unawaited(() async {
                  try {
                    if (plant.reminderEnabled &&
                        !plant.reminderPaused &&
                        !settings.remindersPaused) {
                      await notifier.scheduleNextForPlant(
                        plant: plant,
                        globallyPaused: settings.remindersPaused,
                        pausedUntil: settings.pausedUntil,
                        seasonMultiplier: settings.seasonMode.multiplier,
                      );
                    } else {
                      await notifier.cancelForPlant(plant);
                    }
                  } catch (error, stackTrace) {
                    debugPrint('Failed to update watering reminder: ' +
                        error.toString());
                    debugPrintStack(stackTrace: stackTrace);
                  }
                }());
                if (context.mounted) {
                  Navigator.pop(context, {
                    'event': isEdit ? 'updated' : 'created',
                    'name': plant.name,
                  });
                }
              },
              icon: const Icon(Icons.save),
              label: Text(isEdit ? l10n.saveChanges : l10n.createPlant),
            )
          ],
        ),
      ),
    );
  }
}
