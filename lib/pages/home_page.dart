import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_provider.dart';
import 'package:macetohuerto/l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../utils/transitions.dart';
import '../widgets/plant_card.dart';
import 'plant_form_page.dart';
import '../utils/feedback_overlay.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plants = ref.watch(plantsProvider);
    final query = ref.watch(searchQueryProvider);
    final sort = ref.watch(sortOptionProvider);
    final locationFilter = ref.watch(locationFilterProvider);
    final speciesFilter = ref.watch(speciesFilterProvider);
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    // Reschedule notifications when plants data or settings change
    ref.listen(plantsProvider, (prev, next) {
      final s = ref.read(settingsProvider);
      next.whenData((list) async {
        for (final p in list) {
          if (s.remindersPaused || p.reminderPaused || !p.reminderEnabled) {
            await NotificationService().cancelForPlant(p);
          } else {
            await NotificationService().scheduleNextForPlant(
              plant: p,
              globallyPaused: s.remindersPaused,
              pausedUntil: s.pausedUntil,
            );
          }
        }
      });
    });

    ref.listen(settingsProvider, (prev, next) {
      final state = ref.read(plantsProvider);
      state.whenData((list) async {
        for (final p in list) {
          if (next.remindersPaused || p.reminderPaused || !p.reminderEnabled) {
            await NotificationService().cancelForPlant(p);
          } else {
            await NotificationService().scheduleNextForPlant(
              plant: p,
              globallyPaused: next.remindersPaused,
              pausedUntil: next.pausedUntil,
            );
          }
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: l10n.themeToggleTooltip,
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: const Icon(Icons.brightness_6_outlined),
          ),
          IconButton(
            tooltip: 'Probar notificacion',
            onPressed: () async {
              await NotificationService().ensurePermissions();
              await NotificationService().openExactAlarmSettingsIfNeeded();
              await NotificationService().scheduleTestInSeconds(10);
              if (!context.mounted) return;
              FeedbackOverlay.show(context, text: 'Notificacion de prueba en 10s');
            },
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          IconButton(
            tooltip: 'Pendientes',
            onPressed: () async {
              await NotificationService().debugShowPending(context);
            },
            icon: const Icon(Icons.list_alt_outlined),
          ),
          IconButton(
            tooltip: settings.remindersPaused ? 'Reanudar recordatorios' : 'Pausar recordatorios',
            onPressed: () async {
              final next = !settings.remindersPaused;
              await ref.read(settingsProvider.notifier).setRemindersPaused(next);
              // Reprogramar/cancelar todos
              final state = ref.read(plantsProvider);
              state.whenData((list) async {
                for (final p in list) {
                  if (next) {
                    await NotificationService().cancelForPlant(p);
                  } else {
                    await NotificationService().scheduleNextForPlant(
                      plant: p,
                      globallyPaused: false,
                      pausedUntil: settings.pausedUntil,
                    );
                  }
                }
                if (!context.mounted) return;
                await NotificationService().debugShowPending(context);
              });
            },
            icon: Icon(settings.remindersPaused ? Icons.notifications_off : Icons.notifications_active_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Soft background gradient
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          plants.when(
        data: (list) {
          final q = query.trim().toLowerCase();
          final filteredBase = list.where((p) {
            if (q.isEmpty) return true;
            final haystack = [
              p.name,
              p.species ?? '',
              p.location ?? '',
            ].join(' ').toLowerCase();
            return haystack.contains(q);
          }).where((p) {
            final lf = (locationFilter ?? '').trim();
            if (lf.isEmpty) return true;
            return (p.location ?? '').trim() == lf;
          }).where((p) {
            final sf = (speciesFilter ?? '').trim();
            if (sf.isEmpty) return true;
            return (p.species ?? '').trim() == sf;
          }).toList();

          // Build unique locations list (non-empty)
          final locations = <String>{
            for (final p in list)
              if ((p.location ?? '').trim().isNotEmpty) (p.location ?? '').trim(),
          }.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          final species = <String>{
            for (final p in list)
              if ((p.species ?? '').trim().isNotEmpty) (p.species ?? '').trim(),
          }.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          // Sorting
          int cmpName(a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
          int cmpDate(a, b) {
            final da = a.plantedAt;
            final db = b.plantedAt;
            if (da == null && db == null) return 0;
            if (da == null) return -1;
            if (db == null) return 1;
            return da.compareTo(db);
          }

          final filtered = [...filteredBase];
          switch (sort) {
            case SortOption.nameAsc:
              filtered.sort(cmpName);
              break;
            case SortOption.nameDesc:
              filtered.sort((a, b) => cmpName(b, a));
              break;
            case SortOption.dateAsc:
              filtered.sort(cmpDate);
              break;
            case SortOption.dateDesc:
              filtered.sort((a, b) => cmpDate(b, a));
              break;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.searchHint,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<SortOption>(
                        initialValue: sort,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.orderBy,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: SortOption.nameAsc, child: Text(l10n.nameAZ)),
                          DropdownMenuItem(value: SortOption.nameDesc, child: Text(l10n.nameZA)),
                          DropdownMenuItem(value: SortOption.dateDesc, child: Text(l10n.dateNewest)),
                          DropdownMenuItem(value: SortOption.dateAsc, child: Text(l10n.dateOldest)),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            ref.read(sortOptionProvider.notifier).state = v;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: (locationFilter ?? '').isEmpty ? null : locationFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.location,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<String?>(value: null, child: Text(l10n.all)),
                          ...locations.map((loc) => DropdownMenuItem<String?>(value: loc, child: Text(loc))),
                        ],
                        onChanged: (v) {
                          ref.read(locationFilterProvider.notifier).state = v;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: (speciesFilter ?? '').isEmpty ? null : speciesFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.species,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<String?>(value: null, child: Text(l10n.all)),
                          ...species.map((sp) => DropdownMenuItem<String?>(value: sp, child: Text(sp))),
                        ],
                        onChanged: (v) {
                          ref.read(speciesFilterProvider.notifier).state = v;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (list.isEmpty)
                Expanded(
                  child: Center(child: Text(l10n.emptyList)),
                )
              else if (filtered.isEmpty)
                Expanded(
                  child: Center(child: Text(l10n.noResults)),
                )
              else
                Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: ListView.builder(
                        key: ValueKey(filtered.map((e) => e.id).join(',')),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => PlantCard(
                        key: ValueKey(filtered[index].id),
                        plant: filtered[index],
                        rootScaffoldContext: context,
                      ),
                    ),
                  ),
                ),
              ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(fadeScaleRoute(const PlantFormPage()));
          // Haptic feedback is now triggered on the save button itself
          // to ensure the user feels it at the moment of action.
        },
        label: Text(l10n.addPlant),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
