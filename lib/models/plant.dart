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
  // New fields
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

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
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
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
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
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
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  // Database serialization
  factory Plant.fromDb(Map<String, dynamic> map) {
    return Plant(
      id: map['id'] as String,
      name: map['name'] as String,
      species: map['species'] as String?,
      location: map['location'] as String?,
      plantedAt: map['planted_at'] != null
          ? DateTime.tryParse(map['planted_at'] as String)
          : null,
      notes: map['notes'] as String?,
      reminderEnabled: (map['reminder_enabled'] as int) == 1,
      wateringIntervalDays: map['watering_interval_days'] as int?,
      wateringTime: map['watering_time'] as String?,
      reminderPaused: (map['reminder_paused'] as int) == 1,
      lastWateredAt: map['last_watered_at'] != null
          ? DateTime.tryParse(map['last_watered_at'] as String)
          : null,
      tags: map['tags'] != null
          ? (map['tags'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toDb() => {
        'id': id,
        'name': name,
        'species': species,
        'location': location,
        'planted_at': plantedAt?.toIso8601String(),
        'notes': notes,
        'reminder_enabled': reminderEnabled ? 1 : 0,
        'watering_interval_days': wateringIntervalDays,
        'watering_time': wateringTime,
        'reminder_paused': reminderPaused ? 1 : 0,
        'last_watered_at': lastWateredAt?.toIso8601String(),
        'tags': tags.join(','),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
