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
  final String? type; // order_created | order_status_updated | chat_message

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.timestamp,
    required this.category,
    this.isRead = false,
    this.orderId,
    this.type,
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
    String? type,
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
      type: type ?? this.type,
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

  /// Removes emoji characters (older notifications in the DB contain them).
  static String stripEmojis(String input) {
    return input
        .replaceAll(
          RegExp(
            r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}]',
            unicode: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
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
      title: stripEmojis(json['title']?.toString() ?? ''),
      body: json['body']?.toString() ?? '',
      timeAgo: formatTimeAgo(createdAt),
      timestamp: createdAt,
      category: parseCategory(json['category']?.toString()),
      isRead: json['isRead'] == true,
      orderId: json['orderId']?.toString(),
      type: json['type']?.toString(),
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
      if (type != null) 'type': type,
      'createdAt': timestamp.toIso8601String(),
    };
  }
}
