import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../pages/plant_detail_page.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  const PlantCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(plant.name),
        subtitle: Text([plant.species, plant.location].where((e) => e != null && e.isNotEmpty).join(' · ')),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlantDetailPage(plant: plant)),
          );
        },
      ),
    );
  }
}
