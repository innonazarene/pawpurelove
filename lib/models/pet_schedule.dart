import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'care_log.dart';

enum ScheduleFrequency {
  once,
  daily,
  weekly,
  monthly,
  yearly,
}

extension ScheduleFrequencyExtension on ScheduleFrequency {
  String get label {
    switch (this) {
      case ScheduleFrequency.once: return 'Once';
      case ScheduleFrequency.daily: return 'Daily';
      case ScheduleFrequency.weekly: return 'Weekly';
      case ScheduleFrequency.monthly: return 'Monthly';
      case ScheduleFrequency.yearly: return 'Yearly';
    }
  }
}

class PetSchedule {
  final String id;
  final String petId;
  final String title;
  final CareType type;
  final DateTime nextScheduledDate;
  final ScheduleFrequency frequency;
  final String? notes;
  final bool isActive;

  PetSchedule({
    String? id,
    required this.petId,
    required this.title,
    required this.type,
    required this.nextScheduledDate,
    required this.frequency,
    this.notes,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'petId': petId,
    'title': title,
    'type': type.index,
    'nextScheduledDate': nextScheduledDate.toIso8601String(),
    'frequency': frequency.index,
    'notes': notes,
    'isActive': isActive,
  };

  factory PetSchedule.fromJson(Map<String, dynamic> json) => PetSchedule(
    id: json['id'],
    petId: json['petId'],
    title: json['title'],
    type: CareType.values[json['type']],
    nextScheduledDate: DateTime.parse(json['nextScheduledDate']),
    frequency: ScheduleFrequency.values[json['frequency']],
    notes: json['notes'],
    isActive: json['isActive'] ?? true,
  );

  PetSchedule copyWith({
    String? title,
    CareType? type,
    DateTime? nextScheduledDate,
    ScheduleFrequency? frequency,
    String? notes,
    bool? isActive,
  }) {
    return PetSchedule(
      id: id,
      petId: petId,
      title: title ?? this.title,
      type: type ?? this.type,
      nextScheduledDate: nextScheduledDate ?? this.nextScheduledDate,
      frequency: frequency ?? this.frequency,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  String encode() => jsonEncode(toJson());
  static PetSchedule decode(String str) => PetSchedule.fromJson(jsonDecode(str));
}
