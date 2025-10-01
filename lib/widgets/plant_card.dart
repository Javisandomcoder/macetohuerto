import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/plant.dart';
import '../models/care_log.dart';
import 'package:macetohuerto/l10n/app_localizations.dart';
import '../pages/plant_detail_page.dart';
import '../utils/transitions.dart';
import '../utils/watering_calculator.dart';
import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
import '../utils/feedback_overlay.dart';

class PlantCard extends ConsumerStatefulWidget {
  final Plant plant;
  final BuildContext rootScaffoldContext;
  const PlantCard(
      {super.key, required this.plant, required this.rootScaffoldContext});

  @override
  ConsumerState<PlantCard> createState() => _PlantCardState();
}

class _PlantCardState extends ConsumerState<PlantCard> {
  PlantImage? _thumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final images = await DatabaseService().getPlantImages(widget.plant.id);
    if (images.isNotEmpty && mounted) {
      // Get the most recent image (first in the list, ordered by takenAt DESC)
      setState(() => _thumbnail = images.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final WidgetRef ref = this.ref;
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');
    final initial = widget.plant.name.isNotEmpty ? widget.plant.name[0].toUpperCase() : '??';
    final metaParts = [
      if (widget.plant.species != null && widget.plant.species!.isNotEmpty) widget.plant.species!,
      if (widget.plant.location != null && widget.plant.location!.isNotEmpty) widget.plant.location!,
    ];
    final lastWateredValue = widget.plant.lastWateredAt != null
        ? dateTimeFmt.format(widget.plant.lastWateredAt!)
        : l10n.noWaterData;

    // Calculate next watering and check if needs water soon
    final seasonMultiplier = settings.seasonMode.multiplier;
    final nextWatering = calculateNextWatering(widget.plant, seasonMultiplier: seasonMultiplier);
    final wateringSoon = needsWaterSoon(
      widget.plant,
      globallyPaused: settings.remindersPaused,
      seasonMultiplier: seasonMultiplier,
    );

    return Card(
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            fadeScaleRoute(PlantDetailPage(plant: widget.plant)),
          );
          if (!widget.rootScaffoldContext.mounted) return;
          final rootL10n = AppLocalizations.of(widget.rootScaffoldContext)!;
          if (result is Map && result['event'] == 'deleted') {
            final name = (result['name'] ?? '') as String;
            final Plant? deleted = result['plant'] as Plant?;
            FeedbackOverlay.showWithUndo(
              widget.rootScaffoldContext,
              text: rootL10n.plantDeletedWithName(name),
              undoLabel: rootL10n.undo,
              onUndo: () async {
                if (deleted != null) {
                  await ref.read(plantsProvider.notifier).add(deleted);
                  final settings = ref.read(settingsProvider);
                  if (deleted.reminderEnabled &&
                      !deleted.reminderPaused &&
                      !settings.remindersPaused) {
                    await NotificationService().scheduleNextForPlant(
                      plant: deleted,
                      globallyPaused: settings.remindersPaused,
                      pausedUntil: settings.pausedUntil,
                      seasonMultiplier: settings.seasonMode.multiplier,
                    );
                  }
                }
              },
            );
          } else if (result is Map && result['event'] == 'updated') {
            final name = (result['name'] ?? '') as String;
            FeedbackOverlay.show(widget.rootScaffoldContext,
                text: rootL10n.plantUpdatedWithName(name));
          } else if (result == 'deleted') {
            FeedbackOverlay.show(widget.rootScaffoldContext,
                text: rootL10n.plantDeleted);
          } else if (result == 'updated') {
            FeedbackOverlay.show(widget.rootScaffoldContext,
                text: rootL10n.plantUpdated);
          }

          // Reload thumbnail in case it was updated
          _loadThumbnail();
        },
        child: ListTile(
          leading: Stack(
            children: [
              _thumbnail != null
                  ? CircleAvatar(
                      backgroundImage: FileImage(File(_thumbnail!.imagePath)),
                      onBackgroundImageError: (_, __) {
                        setState(() => _thumbnail = null);
                      },
                    )
                  : CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      child: Text(initial,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
              if (wateringSoon)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.water_drop,
                      size: 10,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ),
            ],
          ),
          title: Hero(
            tag: 'plant-title-${widget.plant.id}',
            flightShuttleBuilder: (ctx, anim, dir, from, to) =>
                FadeTransition(opacity: anim, child: to.widget),
            child:
                Text(widget.plant.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (metaParts.isNotEmpty)
                Text(
                  metaParts.join(' | '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text('${l10n.lastWatered}: $lastWateredValue'),
              if (wateringSoon && nextWatering != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.water_drop,
                          size: 14,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.needsWaterSoon,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
