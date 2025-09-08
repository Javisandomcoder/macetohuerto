import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../pages/plant_detail_page.dart';
import '../utils/transitions.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  const PlantCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final initial = plant.name.isNotEmpty ? plant.name[0].toUpperCase() : '🌱';
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(fadeScaleRoute(PlantDetailPage(plant: plant)));
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Hero(
            tag: 'plant-title-${plant.id}',
            flightShuttleBuilder: (ctx, anim, dir, from, to) => FadeTransition(opacity: anim, child: to.widget),
            child: Text(plant.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          subtitle: Text([
            plant.species,
            plant.location,
          ].where((e) => e != null && e.isNotEmpty).join(' · ')),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
