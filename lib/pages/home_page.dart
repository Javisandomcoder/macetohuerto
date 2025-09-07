import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plant_provider.dart';
import '../widgets/plant_card.dart';
import 'plant_form_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plants = ref.watch(plantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Macetohuerto'),
      ),
      body: plants.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Añade tu primera planta 🌱'),
            );
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) => PlantCard(plant: list[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlantFormPage()),
          );
        },
        label: const Text('Añadir planta'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
