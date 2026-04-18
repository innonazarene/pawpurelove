import 'dart:convert';

enum CareType {
  feeding,
  water,
  walk,
  grooming,
  medication,
  vaccination,
  vetVisit,
  weightLog,
  symptom,
  milestone,
  note,
}

extension CareTypeExtension on CareType {
  String get label {
    switch (this) {
      case CareType.feeding: return 'Feeding';
      case CareType.water: return 'Water';
      case CareType.walk: return 'Walk';
      case CareType.grooming: return 'Grooming';
      case CareType.medication: return 'Medication';
      case CareType.vaccination: return 'Vaccination';
      case CareType.vetVisit: return 'Vet Visit';
      case CareType.weightLog: return 'Weight';
      case CareType.symptom: return 'Symptom';
      case CareType.milestone: return 'Milestone';
      case CareType.note: return 'Note';
    }
  }

  String get category {
    switch (this) {
      case CareType.feeding:
      case CareType.water:
      case CareType.walk:
      case CareType.grooming:
        return 'daily';
      case CareType.medication:
      case CareType.vaccination:
      case CareType.vetVisit:
      case CareType.weightLog:
      case CareType.symptom:
        return 'health';
      case CareType.milestone:
      case CareType.note:
        return 'memory';
    }
  }
}

class CareLog {
  final String id;
  final String petId;
  final CareType type;
  final DateTime dateTime;
  String? title;
  String? notes;
  double? value;
  String? unit;
  bool completed;
  List<String> imagePaths;
  double? latitude;
  double? longitude;
  String? locationName;

  CareLog({
    required this.id,
    required this.petId,
    required this.type,
    required this.dateTime,
    this.title,
    this.notes,
    this.value,
    this.unit,
    this.completed = true,
    List<String>? imagePaths,
    this.latitude,
    this.longitude,
    this.locationName,
  }) : imagePaths = imagePaths ?? [];

  bool get hasImages => imagePaths.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'petId': petId,
    'type': type.index,
    'dateTime': dateTime.toIso8601String(),
    'title': title,
    'notes': notes,
    'value': value,
    'unit': unit,
    'completed': completed,
    'imagePaths': imagePaths,
    'latitude': latitude,
    'longitude': longitude,
    'locationName': locationName,
  };

  factory CareLog.fromJson(Map<String, dynamic> json) => CareLog(
    id: json['id'],
    petId: json['petId'],
    type: CareType.values[json['type']],
    dateTime: DateTime.parse(json['dateTime']),
    title: json['title'],
    notes: json['notes'],
    value: json['value']?.toDouble(),
    unit: json['unit'],
    completed: json['completed'] ?? true,
    imagePaths: (json['imagePaths'] as List<dynamic>?)?.cast<String>() ?? [],
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    locationName: json['locationName'],
  );

  CareLog copyWith({
    DateTime? dateTime,
    String? title,
    String? notes,
    double? value,
    String? unit,
    bool? completed,
    List<String>? imagePaths,
    double? latitude,
    double? longitude,
    String? locationName,
  }) {
    return CareLog(
      id: id,
      petId: petId,
      type: type,
      dateTime: dateTime ?? this.dateTime,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      completed: completed ?? this.completed,
      imagePaths: imagePaths ?? this.imagePaths,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
    );
  }

  String encode() => jsonEncode(toJson());
  static CareLog decode(String str) => CareLog.fromJson(jsonDecode(str));
}
