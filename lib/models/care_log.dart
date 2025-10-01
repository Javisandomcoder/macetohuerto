enum CareType {
  watering('watering'),
  fertilizing('fertilizing'),
  pruning('pruning'),
  transplanting('transplanting'),
  pestControl('pest_control'),
  other('other');

  final String value;
  const CareType(this.value);

  static CareType fromString(String value) {
    return CareType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CareType.other,
    );
  }
}

class CareLog {
  final String id;
  final String plantId;
  final CareType careType;
  final String? notes;
  final DateTime performedAt;

  CareLog({
    required this.id,
    required this.plantId,
    required this.careType,
    this.notes,
    required this.performedAt,
  });

  factory CareLog.fromDb(Map<String, dynamic> map) {
    return CareLog(
      id: map['id'] as String,
      plantId: map['plant_id'] as String,
      careType: CareType.fromString(map['care_type'] as String),
      notes: map['notes'] as String?,
      performedAt: DateTime.parse(map['performed_at'] as String),
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'plant_id': plantId,
      'care_type': careType.value,
      'notes': notes,
      'performed_at': performedAt.toIso8601String(),
    };
  }

  factory CareLog.fromJson(Map<String, dynamic> json) {
    return CareLog(
      id: json['id'] as String,
      plantId: json['plantId'] as String,
      careType: CareType.fromString(json['careType'] as String),
      notes: json['notes'] as String?,
      performedAt: DateTime.parse(json['performedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantId': plantId,
      'careType': careType.value,
      'notes': notes,
      'performedAt': performedAt.toIso8601String(),
    };
  }
}

class PlantImage {
  final int? id;
  final String plantId;
  final String imagePath;
  final String? caption;
  final DateTime takenAt;

  PlantImage({
    this.id,
    required this.plantId,
    required this.imagePath,
    this.caption,
    required this.takenAt,
  });

  factory PlantImage.fromDb(Map<String, dynamic> map) {
    return PlantImage(
      id: map['id'] as int?,
      plantId: map['plant_id'] as String,
      imagePath: map['image_path'] as String,
      caption: map['caption'] as String?,
      takenAt: DateTime.parse(map['taken_at'] as String),
    );
  }

  Map<String, dynamic> toDb() {
    return {
      if (id != null) 'id': id,
      'plant_id': plantId,
      'image_path': imagePath,
      'caption': caption,
      'taken_at': takenAt.toIso8601String(),
    };
  }
}
