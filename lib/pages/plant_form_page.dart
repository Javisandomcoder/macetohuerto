import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/plant.dart';
import '../providers/plant_provider.dart';

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
  DateTime? _plantedAt;

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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar planta' : 'Nueva planta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _speciesCtrl,
              decoration: const InputDecoration(labelText: 'Especie/Variedad'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Ubicación'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(_plantedAt == null
                      ? 'Fecha de plantación: —'
                      : 'Plantada: ${DateFormat('dd/MM/yyyy').format(_plantedAt!)}'),
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
                  child: const Text('Elegir fecha'),
                )
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final id = widget.initial?.id ?? const Uuid().v4();
                final plant = Plant(
                  id: id,
                  name: _nameCtrl.text.trim(),
                  species: _speciesCtrl.text.trim().isEmpty ? null : _speciesCtrl.text.trim(),
                  location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
                  plantedAt: _plantedAt,
                  notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                );
                if (widget.initial == null) {
                  await ref.read(plantsProvider.notifier).add(plant);
                } else {
                  await ref.read(plantsProvider.notifier).update(plant);
                }
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Guardar cambios' : 'Crear planta'),
            )
          ],
        ),
      ),
    );
  }
}
