import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:macetohuerto/l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../providers/settings_provider.dart';
import '../models/plant.dart';
import '../utils/watering_calculator.dart';
import 'plant_form_page.dart';
import 'plant_gallery_page.dart';
import 'care_history_page.dart';
import '../providers/plant_provider.dart';
import 'package:flutter/services.dart';

class PlantDetailPage extends ConsumerStatefulWidget {
  final Plant plant;
  const PlantDetailPage({super.key, required this.plant});

  @override
  ConsumerState<PlantDetailPage> createState() => _PlantDetailPageState();
}

class _PlantDetailPageState extends ConsumerState<PlantDetailPage> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('dd/MM/yyyy');
    final dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');

    final plantsAsync = ref.watch(plantsProvider);

    var currentPlant = widget.plant;

    plantsAsync.maybeWhen(
      data: (plants) {
        final idx = plants.indexWhere((p) => p.id == widget.plant.id);
        if (idx != -1) {
          currentPlant = plants[idx];
        } else if (!_isDeleting) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
        }
      },
      orElse: () {},
    );

    final seasonMultiplier = settings.seasonMode.multiplier;
    final nextWatering = calculateNextWatering(currentPlant, seasonMultiplier: seasonMultiplier);

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'plant-title-${currentPlant.id}',
          flightShuttleBuilder: (ctx, anim, dir, from, to) =>
              FadeTransition(opacity: anim, child: to.widget),
          child: Text(currentPlant.name),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de cuidados',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CareHistoryPage(plant: currentPlant),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Galería de fotos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PlantGalleryPage(plant: currentPlant),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final res = await Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 260),
                  reverseTransitionDuration: const Duration(milliseconds: 220),
                  pageBuilder: (_, a, __) =>
                      PlantFormPage(initial: currentPlant),
                  transitionsBuilder: (_, a, __, child) {
                    final curved = CurvedAnimation(
                      parent: a,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    );
                    return FadeTransition(
                      opacity: curved,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.98, end: 1.0).animate(curved),
                        child: child,
                      ),
                    );
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
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        Navigator.pop(ctx, true);
                      },
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                if (!mounted) return;
                setState(() {
                  _isDeleting = true;
                });
                await ref.read(plantsProvider.notifier).remove(currentPlant.id);
                await NotificationService().cancelForPlant(currentPlant);
                if (!mounted) return;
                Navigator.pop(context, {
                  'event': 'deleted',
                  'name': currentPlant.name,
                  'plant': currentPlant,
                });
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(context, l10n.speciesVariety, currentPlant.species ?? '-'),
          _tile(context, l10n.location, currentPlant.location ?? '-'),
          _tile(
            context,
            l10n.plantedDate,
            currentPlant.plantedAt != null
                ? dateFmt.format(currentPlant.plantedAt!)
                : '-',
          ),
          const SizedBox(height: 16),
          Text(l10n.notes, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(currentPlant.notes ?? '-'),
          const SizedBox(height: 24),
          Text(l10n.watering,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _tile(context, l10n.reminder,
              currentPlant.reminderEnabled ? l10n.enabled : l10n.disabled),
          _tile(
            context,
            l10n.intervalDays,
            currentPlant.wateringIntervalDays != null
                ? settings.seasonMode == SeasonMode.winter
                    ? '${currentPlant.wateringIntervalDays} días (${(currentPlant.wateringIntervalDays! * 1.5).round()} días en invierno)'
                    : '${currentPlant.wateringIntervalDays} días'
                : '-',
          ),
          _tile(context, l10n.time, currentPlant.wateringTime ?? '-'),
          _tile(
            context,
            l10n.paused,
            (currentPlant.reminderPaused || settings.remindersPaused)
                ? l10n.yes
                : l10n.no,
          ),
          _tile(
            context,
            l10n.lastWatered,
            currentPlant.lastWateredAt != null
                ? dateTimeFmt.format(currentPlant.lastWateredAt!)
                : l10n.noWaterData,
          ),
          _tile(
            context,
            l10n.nextWatering,
            (currentPlant.reminderPaused || settings.remindersPaused)
                ? l10n.globallyPaused
                : (nextWatering != null
                    ? dateTimeFmt.format(nextWatering)
                    : '-'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final now = DateTime.now();
              final updated = await ref
                  .read(plantsProvider.notifier)
                  .markWatered(currentPlant.id, now);
              if (updated != null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.wateringLogged)),
                  );
                }
              }
            },
            icon: const Icon(Icons.opacity_outlined),
            label: Text(l10n.registerWatering),
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
