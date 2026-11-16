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
  final String? orderId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.timestamp,
    required this.category,
    this.isRead = false,
    this.orderId,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? timeAgo,
    DateTime? timestamp,
    NotificationCategory? category,
    bool? isRead,
    String? orderId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timeAgo: timeAgo ?? this.timeAgo,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      orderId: orderId ?? this.orderId,
    );
  }

  static NotificationCategory parseCategory(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'promotions':
      case 'promo':
        return NotificationCategory.promotions;
      case 'system':
        return NotificationCategory.system;
      case 'orders':
      default:
        return NotificationCategory.orders;
    }
  }

  static String formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'ახლახანს';
    if (diff.inMinutes < 60) return '${diff.inMinutes} წთ წინ';
    if (diff.inHours < 24) return '${diff.inHours} სთ წინ';
    if (diff.inDays < 7) return '${diff.inDays} დღის წინ';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now();
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      timeAgo: formatTimeAgo(createdAt),
      timestamp: createdAt,
      category: parseCategory(json['category']?.toString()),
      isRead: json['isRead'] == true,
      orderId: json['orderId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category.name,
      'isRead': isRead,
      'orderId': orderId,
      'createdAt': timestamp.toIso8601String(),
    };
  }
}
