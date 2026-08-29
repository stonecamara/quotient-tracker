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
  final bool repeatsWeekly;
  final DateTime createdAt;
  final DateTime startDate;
  final List<String> completedDates;

  Activity({
    required this.id,
    required this.name,
    this.description,
    required this.hour,
    required this.minute,
    required List<bool> weeklyDays,
    this.repeatsWeekly = false,
    required this.createdAt,
    DateTime? startDate,
    Iterable<String> completedDates = const [],
  }) : weeklyDays = List<bool>.unmodifiable(weeklyDays),
       startDate = _dateOnly(startDate ?? createdAt),
       completedDates = List<String>.unmodifiable(
         completedDates.where((value) => value.isNotEmpty).toSet(),
       );

  factory Activity.create({
    required String name,
    String? description,
    required int hour,
    required int minute,
    required List<bool> weeklyDays,
    bool repeatsWeekly = false,
    DateTime? startDate,
  }) {
    final now = DateTime.now();
    return Activity(
      id: _uuid.v4(),
      name: name,
      description: description,
      hour: hour,
      minute: minute,
      weeklyDays: weeklyDays,
      repeatsWeekly: repeatsWeekly,
      createdAt: now,
      startDate: startDate ?? now,
    );
  }

  Activity copyWith({
    String? name,
    Object? description = _unset,
    int? hour,
    int? minute,
    List<bool>? weeklyDays,
    bool? repeatsWeekly,
    DateTime? startDate,
    Iterable<String>? completedDates,
  }) {
    return Activity(
      id: id,
      name: name ?? this.name,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      repeatsWeekly: repeatsWeekly ?? this.repeatsWeekly,
      createdAt: createdAt,
      startDate: startDate ?? this.startDate,
      completedDates: completedDates ?? this.completedDates,
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
      'repeatsWeekly': repeatsWeekly,
      'isCompletedToday': isCompletedToday,
      'completedDates': completedDates,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate.toIso8601String(),
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    final days = List<bool>.from(map['weeklyDays'] as List);
    if (days.length != 7) {
      throw const FormatException('weeklyDays doit contenir 7 éléments');
    }
    final createdAt = DateTime.parse(map['createdAt'] as String);
    final storedStartDate = map['startDate'];
    final startDate = storedStartDate is String
        ? DateTime.tryParse(storedStartDate)
        : null;
    final storedCompletedDates = map['completedDates'];
    final completedDates = <String>{
      if (storedCompletedDates is List)
        ...storedCompletedDates.whereType<String>(),
    };

    // Migration des anciennes données qui ne connaissaient que
    // isCompletedToday : cette validation appartient à la date actuelle.
    if (map['isCompletedToday'] == true) {
      completedDates.add(_dateKey(DateTime.now()));
    }

    return Activity(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      weeklyDays: days,
      repeatsWeekly: map['repeatsWeekly'] as bool? ?? false,
      createdAt: createdAt,
      startDate: startDate ?? createdAt,
      completedDates: completedDates,
    );
  }

  String get scheduledTimeFormatted =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  bool isScheduledFor(DateTime date) {
    final day = _dateOnly(date);
    if (!repeatsWeekly) {
      return day == startDate;
    }
    return !day.isBefore(startDate) && weeklyDays[day.weekday - 1];
  }

  bool isCompletedOn(DateTime date) {
    return completedDates.contains(_dateKey(date));
  }

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  Activity withCompletionForDate(DateTime date, bool completed) {
    final key = _dateKey(date);
    final values = completedDates.toSet();
    if (completed) {
      values.add(key);
    } else {
      values.remove(key);
    }
    return copyWith(completedDates: values);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _dateKey(DateTime value) {
    final day = _dateOnly(value);
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }
}
