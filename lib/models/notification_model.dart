class NotificationModel {
  final String name;
  final String time;
  final String? message;
  bool enabled;
  final String category;

  NotificationModel({
    required this.name,
    required this.time,
    this.message,
    this.enabled = true,
    required this.category, // Make sure category is required
  });

  // CopyWith method to create a new instance with updated values
  NotificationModel copyWith({
    String? name,
    String? time,
    String? message,
    bool? enabled,
    String? category, // Added category to copyWith
  }) {
    return NotificationModel(
      name: name ?? this.name,
      time: time ?? this.time,
      message: message ?? this.message,
      enabled: enabled ?? this.enabled,
      category: category ?? this.category, // Handle category
    );
  }

  // Convert NotificationModel to a Map (for saving in SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'time': time,
      'message': message,
      'enabled': enabled,
      'category': category, // Add category to the map
    };
  }

  // Create NotificationModel from a Map
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      name: map['name'],
      time: map['time'],
      message: map['message'],
      enabled: map['enabled'],
      category: map['category'], // Add category when loading
    );
  }
}
