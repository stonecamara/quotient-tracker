class Activity {
  final String id;
  final String name;
  final String? description;
  final int hour;
  final int minute;
  final List<bool> weeklyDays; // [lundi, mardi, mercredi, jeudi, vendredi, samedi, dimanche]
  final bool isCompletedToday;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.name,
    this.description,
    required this.hour,
    required this.minute,
    required this.weeklyDays,
    this.isCompletedToday = false,
    required this.createdAt,
  });

  factory Activity.create({
    required String name,
    String? description,
    required int hour,
    required int minute,
    required List<bool> weeklyDays,
  }) {
    return Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
    String? description,
    int? hour,
    int? minute,
    List<bool>? weeklyDays,
    bool? isCompletedToday,
  }) {
    return Activity(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
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
    return Activity(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      hour: map['hour'],
      minute: map['minute'],
      weeklyDays: List<bool>.from(map['weeklyDays']),
      isCompletedToday: map['isCompletedToday'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String get scheduledTimeFormatted {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  bool get isScheduledForToday {
    final today = DateTime.now().weekday - 1; // 0 = lundi
    return weeklyDays[today];
  }
}
