import 'package:hive/hive.dart';

part 'trophy.g.dart';

@HiveType(typeId: 1)
class Trophy extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String icon;

  @HiveField(4)
  final DateTime unlockedAt;

  Trophy({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlockedAt,
  });

  factory Trophy.create({
    required String name,
    required String description,
    required String icon,
  }) {
    return Trophy(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      icon: icon,
      unlockedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'unlockedAt': unlockedAt.toIso8601String(),
  };

  factory Trophy.fromJson(Map<String, dynamic> json) => Trophy(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    icon: json['icon'],
    unlockedAt: DateTime.parse(json['unlockedAt']),
  );
} 