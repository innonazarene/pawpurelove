import 'dart:convert';

class PetProfile {
  final String id;
  String name;
  String breed;
  int ageYears;
  int ageMonths;
  String gender;
  double weight;
  String? photoPath;
  DateTime createdAt;

  PetProfile({
    required this.id,
    required this.name,
    required this.breed,
    this.ageYears = 0,
    this.ageMonths = 0,
    this.gender = 'Male',
    this.weight = 0.0,
    this.photoPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get ageDisplay {
    if (ageYears > 0 && ageMonths > 0) {
      return '$ageYears yr${ageYears > 1 ? 's' : ''} $ageMonths mo';
    } else if (ageYears > 0) {
      return '$ageYears year${ageYears > 1 ? 's' : ''} old';
    } else {
      return '$ageMonths month${ageMonths > 1 ? 's' : ''} old';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'breed': breed,
    'ageYears': ageYears,
    'ageMonths': ageMonths,
    'gender': gender,
    'weight': weight,
    'photoPath': photoPath,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PetProfile.fromJson(Map<String, dynamic> json) => PetProfile(
    id: json['id'],
    name: json['name'],
    breed: json['breed'],
    ageYears: json['ageYears'] ?? 0,
    ageMonths: json['ageMonths'] ?? 0,
    gender: json['gender'] ?? 'Male',
    weight: (json['weight'] ?? 0.0).toDouble(),
    photoPath: json['photoPath'],
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );

  String encode() => jsonEncode(toJson());
  static PetProfile decode(String str) => PetProfile.fromJson(jsonDecode(str));
}

class DogBreed {
  final String name;
  final String category;
  final IconType icon;

  const DogBreed({required this.name, required this.category, this.icon = IconType.pets});

  static const List<DogBreed> allBreeds = [
    DogBreed(name: 'Aspin', category: 'Mixed'),
    DogBreed(name: 'Golden Retriever', category: 'Sporting'),
    DogBreed(name: 'Labrador Retriever', category: 'Sporting'),
    DogBreed(name: 'German Shepherd', category: 'Herding'),
    DogBreed(name: 'Bulldog', category: 'Non-Sporting'),
    DogBreed(name: 'Poodle', category: 'Non-Sporting'),
    DogBreed(name: 'Beagle', category: 'Hound'),
    DogBreed(name: 'Rottweiler', category: 'Working'),
    DogBreed(name: 'Yorkshire Terrier', category: 'Toy'),
    DogBreed(name: 'Boxer', category: 'Working'),
    DogBreed(name: 'Dachshund', category: 'Hound'),
    DogBreed(name: 'Siberian Husky', category: 'Working'),
    DogBreed(name: 'Shiba Inu', category: 'Non-Sporting'),
    DogBreed(name: 'Corgi', category: 'Herding'),
    DogBreed(name: 'Chihuahua', category: 'Toy'),
    DogBreed(name: 'Pomeranian', category: 'Toy'),
    DogBreed(name: 'Maltese', category: 'Toy'),
    DogBreed(name: 'Shih Tzu', category: 'Toy'),
    DogBreed(name: 'Border Collie', category: 'Herding'),
    DogBreed(name: 'Australian Shepherd', category: 'Herding'),
    DogBreed(name: 'Doberman', category: 'Working'),
    DogBreed(name: 'Great Dane', category: 'Working'),
    DogBreed(name: 'Cavalier King Charles Spaniel', category: 'Toy'),
    DogBreed(name: 'Miniature Schnauzer', category: 'Terrier'),
    DogBreed(name: 'French Bulldog', category: 'Non-Sporting'),
    DogBreed(name: 'Other', category: 'Other'),
  ];
}

enum IconType { pets }
