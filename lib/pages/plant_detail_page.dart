import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plant.dart';
import 'plant_form_page.dart';
import '../providers/plant_provider.dart';

class PlantDetailPage extends ConsumerWidget {
  final Plant plant;
  const PlantDetailPage({super.key, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlantFormPage(initial: plant)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar planta'),
                  content: const Text('¿Seguro que quieres eliminarla? Esta acción no se puede deshacer.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(plantsProvider.notifier).remove(plant.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('Especie/Variedad', plant.species ?? '—'),
          _tile('Ubicación', plant.location ?? '—'),
          _tile('Plantada', plant.plantedAt != null ? '${plant.plantedAt!.day.toString().padLeft(2,'0')}/${plant.plantedAt!.month.toString().padLeft(2,'0')}/${plant.plantedAt!.year}' : '—'),
          const SizedBox(height: 16),
          const Text('Notas', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(plant.notes ?? '—'),
        ],
      ),
    );
  }

  Widget _tile(String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: const TextStyle(color: Colors.black54)),
      subtitle: Text(value),
    );
  }
}
