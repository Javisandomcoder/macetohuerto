import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant.dart';

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return PlantRepository();
});

/// Query de búsqueda simple para filtrar plantas en memoria
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Opciones de ordenación de la lista
enum SortOption { nameAsc, nameDesc, dateDesc, dateAsc }

final sortOptionProvider =
    StateProvider<SortOption>((ref) => SortOption.nameAsc);

/// Filtro por ubicación (null o vacío = todas)
final locationFilterProvider = StateProvider<String?>((ref) => null);

/// Filtro por especie (null o vacío = todas)
final speciesFilterProvider = StateProvider<String?>((ref) => null);

final plantsProvider =
    StateNotifierProvider<PlantsNotifier, AsyncValue<List<Plant>>>((ref) {
  final repo = ref.watch(plantRepositoryProvider);
  return PlantsNotifier(repo)..load();
});

class PlantRepository {
  static const _key = 'plants_json';

  final SharedPreferences? _injectedPrefs;
  PlantRepository({SharedPreferences? prefs}) : _injectedPrefs = prefs;

  Future<SharedPreferences> _prefs() async {
    return _injectedPrefs ?? await SharedPreferences.getInstance();
  }

  Future<List<Plant>> load() async {
    final prefs = await _prefs();
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
    final prefs = await _prefs();
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

  Future<Plant?> markWatered(String id, DateTime wateredAt) async {
    final current = state.value ?? [];
    final idx = current.indexWhere((p) => p.id == id);
    if (idx == -1) return null;
    final updated = [...current];
    final updatedPlant = updated[idx].copyWith(lastWateredAt: wateredAt);
    updated[idx] = updatedPlant;
    state = AsyncValue.data(updated);
    await repo.save(updated);
    return updatedPlant;
  }

  Future<void> remove(String id) async {
    final current = state.value ?? [];
    final updated = current.where((p) => p.id != id).toList();
    state = AsyncValue.data(updated);
    await repo.save(updated);
  }
}
