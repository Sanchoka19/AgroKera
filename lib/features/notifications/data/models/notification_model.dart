enum NotificationCategory {
  all,
  orders,
  promotions,
  system,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final DateTime timestamp;
  final NotificationCategory category;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.timestamp,
    required this.category,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? timeAgo,
    DateTime? timestamp,
    NotificationCategory? category,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timeAgo: timeAgo ?? this.timeAgo,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
    );
  }
}

