import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:macetohuerto/models/plant.dart';
import 'package:macetohuerto/providers/plant_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('PlantRepository saves and loads plants', () async {
    final repo = PlantRepository();

    final plant = Plant(
      id: '1',
      name: 'Tomatera',
      species: 'Cherry',
      location: 'Balcón',
      plantedAt: DateTime(2024, 3, 10),
      notes: 'Sol directo por la mañana',
    );

    await repo.save([plant]);
    final loaded = await repo.load();

    expect(loaded, isNotEmpty);
    expect(loaded.length, 1);
    expect(loaded.first.id, '1');
    expect(loaded.first.name, 'Tomatera');
    expect(loaded.first.species, 'Cherry');
    expect(loaded.first.location, 'Balcón');
    expect(loaded.first.plantedAt, DateTime(2024, 3, 10));
    expect(loaded.first.notes, 'Sol directo por la mañana');
  });
}

