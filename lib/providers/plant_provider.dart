import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant.dart';

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return PlantRepository();
});

final plantsProvider =
    StateNotifierProvider<PlantsNotifier, AsyncValue<List<Plant>>>((ref) {
  final repo = ref.watch(plantRepositoryProvider);
  return PlantsNotifier(repo)..load();
});

class PlantRepository {
  static const _key = 'plants_json';

  Future<List<Plant>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Plant.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Plant> plants) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(plants.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}

class PlantsNotifier extends StateNotifier<AsyncValue<List<Plant>>> {
  final PlantRepository repo;
  PlantsNotifier(this.repo) : super(const AsyncValue.loading());

  Future<void> load() async {
    final list = await repo.load();
    state = AsyncValue.data(list);
  }

  Future<void> add(Plant plant) async {
    final current = state.value ?? [];
    final updated = [...current, plant];
    state = AsyncValue.data(updated);
    await repo.save(updated);
  }

  Future<void> update(Plant plant) async {
    final current = state.value ?? [];
    final idx = current.indexWhere((p) => p.id == plant.id);
    if (idx == -1) return;
    final updated = [...current];
    updated[idx] = plant;
    state = AsyncValue.data(updated);
    await repo.save(updated);
  }

  Future<void> remove(String id) async {
    final current = state.value ?? [];
    final updated = current.where((p) => p.id != id).toList();
    state = AsyncValue.data(updated);
    await repo.save(updated);
  }
}
