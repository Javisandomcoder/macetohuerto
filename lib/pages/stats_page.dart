import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_provider.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../utils/watering_calculator.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final stats = await _db.getStatistics();
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final plants = ref.watch(plantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatCard(
                    context,
                    'Total de plantas',
                    _stats?['totalPlants']?.toString() ?? '0',
                    Icons.eco,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    'Total de cuidados registrados',
                    _stats?['totalCareLogs']?.toString() ?? '0',
                    Icons.history,
                    Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cuidados últimos 30 días',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  plants.when(
                    data: (plantsList) {
                      final recentCare = _stats?['recentCareByType'] as Map<String, dynamic>? ?? {};

                      if (recentCare.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'Sin registros recientes',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          _buildCareTypeRow(
                            context,
                            'Riegos',
                            recentCare['watering']?.toString() ?? '0',
                            Icons.water_drop,
                          ),
                          _buildCareTypeRow(
                            context,
                            'Abonados',
                            recentCare['fertilizing']?.toString() ?? '0',
                            Icons.grass,
                          ),
                          _buildCareTypeRow(
                            context,
                            'Podas',
                            recentCare['pruning']?.toString() ?? '0',
                            Icons.content_cut,
                          ),
                          _buildCareTypeRow(
                            context,
                            'Trasplantes',
                            recentCare['transplanting']?.toString() ?? '0',
                            Icons.change_circle,
                          ),
                          _buildCareTypeRow(
                            context,
                            'Control de plagas',
                            recentCare['pest_control']?.toString() ?? '0',
                            Icons.bug_report,
                          ),
                          _buildCareTypeRow(
                            context,
                            'Otros',
                            recentCare['other']?.toString() ?? '0',
                            Icons.more_horiz,
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, st) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 24),
                  plants.when(
                    data: (plantsList) {
                      final settingsSnapshot = ref.read(settingsProvider);
                      int needsWaterSoonCount = 0;

                      for (final plant in plantsList) {
                        if (needsWaterSoon(
                          plant,
                          globallyPaused: settingsSnapshot.remindersPaused,
                          seasonMultiplier: settingsSnapshot.seasonMode.multiplier,
                        )) {
                          needsWaterSoonCount++;
                        }
                      }

                      return _buildStatCard(
                        context,
                        'Plantas que necesitan riego pronto',
                        needsWaterSoonCount.toString(),
                        Icons.water_drop_outlined,
                        needsWaterSoonCount > 0 ? Colors.orange : Colors.grey,
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareTypeRow(
    BuildContext context,
    String label,
    String count,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(
          count,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
