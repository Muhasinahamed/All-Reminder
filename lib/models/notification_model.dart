class NotificationModel {
  final int id;
  final String name;
  final String time;
  final String? message;
  bool enabled;
  final String category;
  final List<int> repeatDays; // 1 = Monday, ..., 7 = Sunday
  final String? sound;

  NotificationModel({
    int? id,
    required this.name,
    required this.time,
    this.message,
    this.enabled = true,
    required this.category,
    List<int>? repeatDays,
    this.sound,
  })  : id = id ?? (DateTime.now().millisecondsSinceEpoch % 100000000),
        repeatDays = repeatDays ?? const [1, 2, 3, 4, 5, 6, 7];

  NotificationModel copyWith({
    int? id,
    String? name,
    String? time,
    String? message,
    bool? enabled,
    String? category,
    List<int>? repeatDays,
    String? sound,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      message: message ?? this.message,
      enabled: enabled ?? this.enabled,
      category: category ?? this.category,
      repeatDays: repeatDays ?? this.repeatDays,
      sound: sound ?? this.sound,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'message': message,
      'enabled': enabled,
      'category': category,
      'repeatDays': repeatDays,
      'sound': sound,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? (map['name']?.hashCode ?? 0).abs() % 100000,
      name: map['name'],
      time: map['time'],
      message: map['message'],
      enabled: map['enabled'] ?? true,
      category: map['category'],
      repeatDays: map['repeatDays'] != null
          ? List<int>.from(map['repeatDays'])
          : const [1, 2, 3, 4, 5, 6, 7],
      sound: map['sound'],
    );
  }
}
