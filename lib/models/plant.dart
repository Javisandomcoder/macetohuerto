class Plant {
  final String id;
  final String name;
  final String? species;
  final String? location;
  final DateTime? plantedAt;
  final String? notes;

  Plant({
    required this.id,
    required this.name,
    this.species,
    this.location,
    this.plantedAt,
    this.notes,
  });

  Plant copyWith({
    String? id,
    String? name,
    String? species,
    String? location,
    DateTime? plantedAt,
    String? notes,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      location: location ?? this.location,
      plantedAt: plantedAt ?? this.plantedAt,
      notes: notes ?? this.notes,
    );
  }

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as String,
      name: json['name'] as String,
      species: json['species'] as String?,
      location: json['location'] as String?,
      plantedAt: json['plantedAt'] != null
          ? DateTime.tryParse(json['plantedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species,
        'location': location,
        'plantedAt': plantedAt?.toIso8601String(),
        'notes': notes,
      };
}
