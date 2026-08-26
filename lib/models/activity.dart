import 'package:uuid/uuid.dart';

class Activity {
  static const _unset = Object();
  static const _uuid = Uuid();

  final String id;
  final String name;
  final String? description;
  final int hour;
  final int minute;
  final List<bool> weeklyDays;
  final bool isCompletedToday;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.name,
    this.description,
    required this.hour,
    required this.minute,
    required List<bool> weeklyDays,
    this.isCompletedToday = false,
    required this.createdAt,
  }) : weeklyDays = List<bool>.unmodifiable(weeklyDays);

  factory Activity.create({
    required String name,
    String? description,
    required int hour,
    required int minute,
    required List<bool> weeklyDays,
  }) {
    return Activity(
      id: _uuid.v4(),
      name: name,
      description: description,
      hour: hour,
      minute: minute,
      weeklyDays: weeklyDays,
      createdAt: DateTime.now(),
    );
  }

  Activity copyWith({
    String? name,
    Object? description = _unset,
    int? hour,
    int? minute,
    List<bool>? weeklyDays,
    bool? isCompletedToday,
  }) {
    return Activity(
      id: id,
      name: name ?? this.name,
      description: identical(description, _unset) ? this.description : description as String?,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'hour': hour,
      'minute': minute,
      'weeklyDays': weeklyDays,
      'isCompletedToday': isCompletedToday,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    final days = List<bool>.from(map['weeklyDays'] as List);
    if (days.length != 7) {
      throw const FormatException('weeklyDays doit contenir 7 éléments');
    }
    return Activity(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      weeklyDays: days,
      isCompletedToday: map['isCompletedToday'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String get scheduledTimeFormatted =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  bool get isScheduledForToday {
    final today = DateTime.now().weekday - 1;
    return weeklyDays[today];
  }
}
