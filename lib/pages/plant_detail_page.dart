import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macetohuerto/l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../providers/settings_provider.dart';
import '../models/plant.dart';
import 'plant_form_page.dart';
import '../providers/plant_provider.dart';
import 'package:flutter/services.dart';

class PlantDetailPage extends ConsumerWidget {
  final Plant plant;
  const PlantDetailPage({super.key, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');

    DateTime? computeNext() {
      if (!plant.reminderEnabled || plant.wateringIntervalDays == null || plant.wateringTime == null) return null;
      final parts = plant.wateringTime!.split(':');
      final hh = int.tryParse(parts[0]) ?? 9;
      final mm = int.tryParse(parts[1]) ?? 0;
      final now = DateTime.now();
      DateTime baseline = plant.lastWateredAt ?? plant.plantedAt ?? now;
      baseline = DateTime(baseline.year, baseline.month, baseline.day);
      final interval = plant.wateringIntervalDays!;
      DateTime next = DateTime(baseline.year, baseline.month, baseline.day, hh, mm);
      while (!next.isAfter(now)) {
        baseline = baseline.add(Duration(days: interval));
        next = DateTime(baseline.year, baseline.month, baseline.day, hh, mm);
        if (interval <= 0) break;
      }
      return next;
    }
    final nextWatering = computeNext();
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
              final res = await Navigator.of(context).push(
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
              if (res is Map && res['event'] == 'updated') {
                final name = (res['name'] ?? '') as String;
                if (context.mounted) {
                  final l10n = AppLocalizations.of(context)!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.plantUpdatedWithName(name))),
                  );
                }
              }
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
                    FilledButton(
                      onPressed: () {
                        // Strong haptic on destructive action
                        HapticFeedback.heavyImpact();
                        Navigator.pop(ctx, true);
                      },
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(plantsProvider.notifier).remove(plant.id);
                await NotificationService().cancelForPlant(plant);
                if (context.mounted) {
                  Navigator.pop(context, {
                    'event': 'deleted',
                    'name': plant.name,
                    'plant': plant,
                  });
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(context, l10n.speciesVariety, plant.species ?? '—'),
          _tile(context, l10n.location, plant.location ?? '—'),
          _tile(context, l10n.plantedDate, plant.plantedAt != null ? dateFmt.format(plant.plantedAt!) : '—'),
          const SizedBox(height: 16),
          Text(l10n.notes, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(plant.notes ?? '—'),
          const SizedBox(height: 24),
          Text(l10n.watering, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _tile(context, l10n.reminder, plant.reminderEnabled ? l10n.enabled : l10n.disabled),
          _tile(context, l10n.intervalDays, plant.wateringIntervalDays?.toString() ?? '—'),
          _tile(context, l10n.time, plant.wateringTime ?? '—'),
          _tile(context, l10n.paused, (plant.reminderPaused || settings.remindersPaused) ? l10n.yes : l10n.no),
          _tile(context, l10n.lastWatered, plant.lastWateredAt != null ? dateTimeFmt.format(plant.lastWateredAt!) : '—'),
          _tile(
            context,
            l10n.nextWatering,
            (plant.reminderPaused || settings.remindersPaused)
                ? l10n.globallyPaused
                : (nextWatering != null ? dateTimeFmt.format(nextWatering) : '—'),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: theme.textTheme.labelMedium),
      subtitle: Text(value),
    );
  }
}
