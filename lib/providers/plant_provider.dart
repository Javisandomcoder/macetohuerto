import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant.dart';
import '../services/database_service.dart';

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

/// Vista: lista o cuadrícula
enum ViewMode { list, grid }
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.list);

final plantsProvider =
    StateNotifierProvider<PlantsNotifier, AsyncValue<List<Plant>>>((ref) {
  final repo = ref.watch(plantRepositoryProvider);
  return PlantsNotifier(repo)..load();
});

class PlantRepository {
  static const _key = 'plants_json';
  static const _migratedKey = 'migrated_to_sqlite_v1';

  final DatabaseService _db = DatabaseService();

  Future<List<Plant>> load() async {
    // Check if migration is needed
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_migratedKey) ?? false;

    if (!migrated) {
      // Attempt migration from SharedPreferences
      await _migrateFromSharedPreferences(prefs);
    }

    return await _db.getAllPlants();
  }

  Future<void> _migrateFromSharedPreferences(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => Plant.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          await _db.migrateFromSharedPreferences(list);
          // Clear old data
          await prefs.remove(_key);
        }
      } catch (e) {
        // Migration failed, continue anyway
      }
    }
    await prefs.setBool(_migratedKey, true);
  }

  Future<void> save(List<Plant> plants) async {
    // Not used anymore, kept for compatibility
  }

  Future<void> insert(Plant plant) async {
    await _db.insertPlant(plant);
  }

  Future<void> update(Plant plant) async {
    await _db.updatePlant(plant);
  }

  Future<void> delete(String id) async {
    await _db.deletePlant(id);
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
    await repo.insert(plant);
    final current = state.value ?? [];
    final updated = [...current, plant];
    state = AsyncValue.data(updated);
  }

  Future<void> update(Plant plant) async {
    await repo.update(plant);
    final current = state.value ?? [];
    final idx = current.indexWhere((p) => p.id == plant.id);
    if (idx == -1) return;
    final updated = [...current];
    updated[idx] = plant;
    state = AsyncValue.data(updated);
  }

  Future<Plant?> markWatered(String id, DateTime wateredAt) async {
    final current = state.value ?? [];
    final idx = current.indexWhere((p) => p.id == id);
    if (idx == -1) return null;
    final updated = [...current];
    final updatedPlant = updated[idx].copyWith(lastWateredAt: wateredAt);
    updated[idx] = updatedPlant;
    await repo.update(updatedPlant);
    state = AsyncValue.data(updated);
    return updatedPlant;
  }

  Future<void> remove(String id) async {
    await repo.delete(id);
    final current = state.value ?? [];
    final updated = current.where((p) => p.id != id).toList();
    state = AsyncValue.data(updated);
  }
}
