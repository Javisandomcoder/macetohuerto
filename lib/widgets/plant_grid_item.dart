import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plant.dart';
import '../models/care_log.dart';
import '../pages/plant_detail_page.dart';
import '../utils/transitions.dart';
import '../utils/watering_calculator.dart';
import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
import '../utils/feedback_overlay.dart';

class PlantGridItem extends ConsumerStatefulWidget {
  final Plant plant;
  final BuildContext rootScaffoldContext;

  const PlantGridItem({
    super.key,
    required this.plant,
    required this.rootScaffoldContext,
  });

  @override
  ConsumerState<PlantGridItem> createState() => _PlantGridItemState();
}

class _PlantGridItemState extends ConsumerState<PlantGridItem> {
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
    final settings = ref.watch(settingsProvider);
    final seasonMultiplier = settings.seasonMode.multiplier;
    final wateringSoon = needsWaterSoon(
      widget.plant,
      globallyPaused: settings.remindersPaused,
      seasonMultiplier: seasonMultiplier,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            fadeScaleRoute(PlantDetailPage(plant: widget.plant)),
          );
          if (!widget.rootScaffoldContext.mounted) return;

          if (result is Map && result['event'] == 'deleted') {
            final name = (result['name'] ?? '') as String;
            final Plant? deleted = result['plant'] as Plant?;
            FeedbackOverlay.showWithUndo(
              widget.rootScaffoldContext,
              text: 'Planta "$name" eliminada',
              undoLabel: 'Deshacer',
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
          }

          // Reload thumbnail in case it was updated
          _loadThumbnail();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or placeholder
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _thumbnail != null
                      ? Image.file(
                          File(_thumbnail!.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, error, stack) => _buildPlaceholder(context),
                        )
                      : _buildPlaceholder(context),
                  if (wateringSoon)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.water_drop,
                          size: 16,
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.plant.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.plant.species != null && widget.plant.species!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.plant.species!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final initial = widget.plant.name.isNotEmpty ? widget.plant.name[0].toUpperCase() : '?';
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
