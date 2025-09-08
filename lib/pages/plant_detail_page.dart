import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macetohuerto/l10n/app_localizations.dart';
import '../services/notification_service.dart';
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
        title: Hero(
          tag: 'plant-title-${plant.id}',
          flightShuttleBuilder: (ctx, anim, dir, from, to) => FadeTransition(opacity: anim, child: to.widget),
          child: Text(plant.name),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 260),
                  reverseTransitionDuration: const Duration(milliseconds: 220),
                  pageBuilder: (_, a, __) => PlantFormPage(initial: plant),
                  transitionsBuilder: (_, a, __, child) {
                    final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
                    return FadeTransition(opacity: curved, child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(curved), child: child));
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final l10n = AppLocalizations.of(context)!;
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.deletePlantTitle),
                  content: Text(l10n.deletePlantMessage),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(plantsProvider.notifier).remove(plant.id);
                await NotificationService().cancelForPlant(plant);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(AppLocalizations.of(context)!.speciesVariety, plant.species ?? '—'),
          _tile(AppLocalizations.of(context)!.location, plant.location ?? '—'),
          _tile(AppLocalizations.of(context)!.plantedDate, plant.plantedAt != null ? DateFormat('dd/MM/yyyy').format(plant.plantedAt!) : '—'),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.notes, style: const TextStyle(fontWeight: FontWeight.bold)),
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
