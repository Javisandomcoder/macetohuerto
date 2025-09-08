class Plant {
  final String id;
  final String name;
  final String? species;
  final String? location;
  final DateTime? plantedAt;
  final String? notes;
  // Reminder fields
  final bool reminderEnabled;
  final int? wateringIntervalDays; // e.g., 1, 2, 3, 7, 14
  final String? wateringTime; // 'HH:mm'
  final bool reminderPaused; // individual pause
  final DateTime? lastWateredAt;

  Plant({
    required this.id,
    required this.name,
    this.species,
    this.location,
    this.plantedAt,
    this.notes,
    this.reminderEnabled = false,
    this.wateringIntervalDays,
    this.wateringTime,
    this.reminderPaused = false,
    this.lastWateredAt,
  });

  Plant copyWith({
    String? id,
    String? name,
    String? species,
    String? location,
    DateTime? plantedAt,
    String? notes,
    bool? reminderEnabled,
    int? wateringIntervalDays,
    String? wateringTime,
    bool? reminderPaused,
    DateTime? lastWateredAt,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      location: location ?? this.location,
      plantedAt: plantedAt ?? this.plantedAt,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
      wateringTime: wateringTime ?? this.wateringTime,
      reminderPaused: reminderPaused ?? this.reminderPaused,
      lastWateredAt: lastWateredAt ?? this.lastWateredAt,
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
      reminderEnabled: (json['reminderEnabled'] as bool?) ?? false,
      wateringIntervalDays: (json['wateringIntervalDays'] as num?)?.toInt(),
      wateringTime: json['wateringTime'] as String?,
      reminderPaused: (json['reminderPaused'] as bool?) ?? false,
      lastWateredAt: json['lastWateredAt'] != null
          ? DateTime.tryParse(json['lastWateredAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species,
        'location': location,
        'plantedAt': plantedAt?.toIso8601String(),
        'notes': notes,
        'reminderEnabled': reminderEnabled,
        'wateringIntervalDays': wateringIntervalDays,
        'wateringTime': wateringTime,
        'reminderPaused': reminderPaused,
        'lastWateredAt': lastWateredAt?.toIso8601String(),
      };
}
