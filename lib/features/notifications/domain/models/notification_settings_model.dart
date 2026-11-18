/// User preferences for receiving push and in-app notifications
class NotificationSettings {
  final bool ordersEnabled;
  final bool chatEnabled;
  final bool promotionsEnabled;
  final bool inAppToastEnabled;

  const NotificationSettings({
    this.ordersEnabled = true,
    this.chatEnabled = true,
    this.promotionsEnabled = true,
    this.inAppToastEnabled = true,
  });

  NotificationSettings copyWith({
    bool? ordersEnabled,
    bool? chatEnabled,
    bool? promotionsEnabled,
    bool? inAppToastEnabled,
  }) {
    return NotificationSettings(
      ordersEnabled: ordersEnabled ?? this.ordersEnabled,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      promotionsEnabled: promotionsEnabled ?? this.promotionsEnabled,
      inAppToastEnabled: inAppToastEnabled ?? this.inAppToastEnabled,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      ordersEnabled: json['ordersEnabled'] != false,
      chatEnabled: json['chatEnabled'] != false,
      promotionsEnabled: json['promotionsEnabled'] != false,
      inAppToastEnabled: json['inAppToastEnabled'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ordersEnabled': ordersEnabled,
      'chatEnabled': chatEnabled,
      'promotionsEnabled': promotionsEnabled,
      'inAppToastEnabled': inAppToastEnabled,
    };
  }

  /// Evaluates whether an incoming notification should be delivered based on preferences
  bool shouldDeliver({String? category, String? type}) {
    if (type == 'chat_message') {
      return chatEnabled;
    }
    if (category == 'promotions') {
      return promotionsEnabled;
    }
    if (category == 'orders') {
      return ordersEnabled;
    }
    return true;
  }
}

