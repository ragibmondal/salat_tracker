import 'package:hive/hive.dart';

part 'prayer.g.dart';

@HiveType(typeId: 0)
class Prayer extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final DateTime scheduledTime;

  @HiveField(4)
  DateTime? completedTime;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  bool isQaza;

  @HiveField(7)
  String? qazaDate;

  Prayer({
    required this.id,
    required this.name,
    required this.date,
    required this.scheduledTime,
    this.completedTime,
    this.isCompleted = false,
    this.isQaza = false,
    this.qazaDate,
  });

  factory Prayer.create({
    required String name,
    required DateTime date,
    required DateTime scheduledTime,
  }) {
    return Prayer(
      id: '${name}_${date.toIso8601String()}',
      name: name,
      date: date,
      scheduledTime: scheduledTime,
    );
  }

  void markAsCompleted(DateTime completionTime) {
    completedTime = completionTime;
    isCompleted = true;
    isQaza = completionTime.difference(scheduledTime).inHours >= 1;
    save();
  }

  void markAsQaza(String date) {
    isCompleted = false;
    isQaza = true;
    qazaDate = date;
    completedTime = null;
    save();
  }

  void reset() {
    isCompleted = false;
    isQaza = false;
    qazaDate = null;
    completedTime = null;
    save();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'date': date.toIso8601String(),
    'scheduledTime': scheduledTime.toIso8601String(),
    'completedTime': completedTime?.toIso8601String(),
    'isCompleted': isCompleted,
    'isQaza': isQaza,
    'qazaDate': qazaDate,
  };

  factory Prayer.fromJson(Map<String, dynamic> json) => Prayer(
    id: json['id'],
    name: json['name'],
    date: DateTime.parse(json['date']),
    scheduledTime: DateTime.parse(json['scheduledTime']),
    completedTime: json['completedTime'] != null ? DateTime.parse(json['completedTime']) : null,
    isCompleted: json['isCompleted'],
    isQaza: json['isQaza'],
    qazaDate: json['qazaDate'],
  );

  Prayer copyWith({
    String? name,
    DateTime? scheduledTime,
    bool? isCompleted,
    DateTime? completedTime,
    bool? isQaza,
    String? qazaDate,
  }) {
    return Prayer(
      id: id,
      name: name ?? this.name,
      date: date,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      completedTime: completedTime ?? this.completedTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isQaza: isQaza ?? this.isQaza,
      qazaDate: qazaDate ?? this.qazaDate,
    );
  }
} 