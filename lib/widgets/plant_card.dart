import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plant.dart';
import 'package:macetohuerto/l10n/app_localizations.dart';
import '../pages/plant_detail_page.dart';
import '../utils/transitions.dart';
import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../utils/feedback_overlay.dart';

class PlantCard extends ConsumerWidget {
  final Plant plant;
  final BuildContext rootScaffoldContext;
  const PlantCard({super.key, required this.plant, required this.rootScaffoldContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = plant.name.isNotEmpty ? plant.name[0].toUpperCase() : '🌱';
    return Card(
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            fadeScaleRoute(PlantDetailPage(plant: plant)),
          );
          // Use a stable context (rootScaffoldContext) after awaiting navigation
          final l10n = AppLocalizations.of(rootScaffoldContext)!;
          if (result is Map && result['event'] == 'deleted') {
            final name = (result['name'] ?? '') as String;
            final Plant? deleted = result['plant'] as Plant?;
            FeedbackOverlay.showWithUndo(
              rootScaffoldContext,
              text: l10n.plantDeletedWithName(name),
              undoLabel: l10n.undo,
              onUndo: () async {
                if (deleted != null) {
                  await ref.read(plantsProvider.notifier).add(deleted);
                  final settings = ref.read(settingsProvider);
                  if (deleted.reminderEnabled && !deleted.reminderPaused && !settings.remindersPaused) {
                    await NotificationService().scheduleNextForPlant(
                      plant: deleted,
                      globallyPaused: settings.remindersPaused,
                      pausedUntil: settings.pausedUntil,
                    );
                  }
                }
              },
            );
          } else if (result is Map && result['event'] == 'updated') {
            final name = (result['name'] ?? '') as String;
            FeedbackOverlay.show(rootScaffoldContext, text: l10n.plantUpdatedWithName(name));
          } else if (result == 'deleted') {
            FeedbackOverlay.show(rootScaffoldContext, text: l10n.plantDeleted);
          } else if (result == 'updated') {
            FeedbackOverlay.show(rootScaffoldContext, text: l10n.plantUpdated);
          }
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Hero(
            tag: 'plant-title-${plant.id}',
            flightShuttleBuilder: (ctx, anim, dir, from, to) => FadeTransition(opacity: anim, child: to.widget),
            child: Text(plant.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          subtitle: Text([
            plant.species,
            plant.location,
          ].where((e) => e != null && e.isNotEmpty).join(' · ')),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
