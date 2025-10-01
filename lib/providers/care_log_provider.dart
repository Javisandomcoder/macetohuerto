import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/care_log.dart';
import '../services/database_service.dart';

final careLogRepositoryProvider = Provider<CareLogRepository>((ref) {
  return CareLogRepository();
});

final careLogsProvider = StateNotifierProvider.family<CareLogsNotifier, AsyncValue<List<CareLog>>, String>(
  (ref, plantId) {
    final repo = ref.watch(careLogRepositoryProvider);
    return CareLogsNotifier(repo, plantId)..load();
  },
);

class CareLogRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<CareLog>> loadForPlant(String plantId) async {
    return await _db.getCareLogs(plantId);
  }

  Future<void> insert(CareLog log) async {
    await _db.insertCareLog(log);
  }

  Future<void> delete(String id) async {
    await _db.deleteCareLog(id);
  }
}

class CareLogsNotifier extends StateNotifier<AsyncValue<List<CareLog>>> {
  final CareLogRepository repo;
  final String plantId;

  CareLogsNotifier(this.repo, this.plantId) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await repo.loadForPlant(plantId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(CareLog log) async {
    await repo.insert(log);
    final current = state.value ?? [];
    final updated = [log, ...current];
    state = AsyncValue.data(updated);
  }

  Future<void> remove(String id) async {
    await repo.delete(id);
    final current = state.value ?? [];
    final updated = current.where((log) => log.id != id).toList();
    state = AsyncValue.data(updated);
  }
}
