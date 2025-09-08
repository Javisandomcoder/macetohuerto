import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:macetohuerto/models/plant.dart';
import 'package:macetohuerto/providers/plant_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('PlantsNotifier CRUD flow', () async {
    final repo = PlantRepository();
    final notifier = PlantsNotifier(repo);

    await notifier.load();
    expect(notifier.state.value, isEmpty);

    final plant = Plant(id: '1', name: 'Albahaca');
    await notifier.add(plant);
    expect(notifier.state.value?.length, 1);
    expect(notifier.state.value?.first.name, 'Albahaca');

    final updated = plant.copyWith(name: 'Albahaca Genovesa');
    await notifier.update(updated);
    expect(notifier.state.value?.first.name, 'Albahaca Genovesa');

    await notifier.remove('1');
    expect(notifier.state.value, isEmpty);
  });
}

