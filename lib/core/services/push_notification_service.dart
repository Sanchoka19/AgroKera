import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('FCM Background message: ${message.messageId}');
  }
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  FirebaseMessaging? get _fcm {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// When user is viewing a chat, this holds the orderId so foreground notifications
  /// for that same order are suppressed from showing a pop-up head-up banner.
  static String? activeChatOrderId;

  static const AndroidNotificationChannel _ordersChannel =
      AndroidNotificationChannel(
    'agrokera_orders_channel',
    'შეკვეთების შეტყობინებები',
    description: 'შეკვეთების მიღება, სტატუსის ცვლილებები და PIN კოდი',
    importance: Importance.max,
    playSound: true,
  );

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
    'agrokera_chat_channel',
    'ჩათის შეტყობინებები',
    description: 'შეტყობინებები ფერმერთან და კლიენტთან ჩათიდან',
    importance: Importance.high,
    playSound: true,
  );

  static const AndroidNotificationChannel _promotionsChannel =
      AndroidNotificationChannel(
    'agrokera_promotions_channel',
    'სიახლეები და აქციები',
    description: 'სეზონური ფასდაკლებები და შეთავაზებები',
    importance: Importance.defaultImportance,
    playSound: false,
  );

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'agrokera_high_importance_channel',
    'AgroKera შეტყობინებები',
    description: 'მნიშვნელოვანი შეტყობინებები შეკვეთებისა და სიახლეების შესახებ',
    importance: Importance.max,
    playSound: true,
  );

  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  void Function(String token)? _onTokenUpdated;
  void Function(String token)? get onTokenUpdated => _onTokenUpdated;

  set onTokenUpdated(void Function(String token)? handler) {
    _onTokenUpdated = handler;
    final token = _fcmToken;
    if (handler != null && token != null && token.isNotEmpty) {
      handler(token);
    }
  }

  /// Called when the user taps a notification (push or local).
  /// Receives the FCM `data` payload (orderId, type, category...).
  void Function(Map<String, dynamic> data)? _onNotificationTap;
  Map<String, dynamic>? _pendingTapData;

  set onNotificationTap(void Function(Map<String, dynamic> data)? handler) {
    _onNotificationTap = handler;
    final pending = _pendingTapData;
    if (handler != null && pending != null) {
      _pendingTapData = null;
      handler(pending);
    }
  }

  void _handleTap(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    final handler = _onNotificationTap;
    if (handler == null) {
      _pendingTapData = data; // app not ready yet, deliver later
    } else {
      handler(data);
    }
  }

  Future<void> initialize({Function(RemoteMessage)? onForegroundMessage}) async {
    final fcm = _fcm;
    if (fcm == null) return;

    // 1. Set background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permissions (Android 13+ and iOS)
    NotificationSettings settings = await fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('FCM Permission status: ${settings.authorizationStatus}');
    }

    // 3. Setup Android notification channels for head-up notifications
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_ordersChannel);
      await androidPlugin?.createNotificationChannel(_chatChannel);
      await androidPlugin?.createNotificationChannel(_promotionsChannel);
      await androidPlugin?.createNotificationChannel(_channel);
    }

    // 4. Initialize flutter_local_notifications (18.x API)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('Local notification tapped: ${response.payload}');
        }
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map) {
              _handleTap(Map<String, dynamic>.from(decoded));
            }
          } catch (_) {}
        }
      },
    );

    // 5. Foreground notification presentation options
    await fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 6. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message received: ${message.notification?.title}');
      }

      final type = message.data['type']?.toString();
      final orderId = message.data['orderId']?.toString();

      // If the user is currently looking at this order's chat screen, suppress heads-up push banner
      if (type == 'chat_message' &&
          orderId != null &&
          orderId == activeChatOrderId) {
        if (kDebugMode) {
          print('Foreground chat message suppressed for active order: $orderId');
        }
        if (onForegroundMessage != null) onForegroundMessage(message);
        return;
      }

      final RemoteNotification? notification = message.notification;
      final AndroidNotification? android = message.notification?.android;

      if (notification != null && Platform.isAndroid) {
        final isChat = type == 'chat_message' ||
            (notification.title?.contains('შეტყობინება') ?? false);
        final isPromo = message.data['category'] == 'promotions';

        final targetChannel = isChat
            ? _chatChannel
            : isPromo
                ? _promotionsChannel
                : _ordersChannel;

        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              targetChannel.id,
              targetChannel.name,
              channelDescription: targetChannel.description,
              icon: android?.smallIcon ?? '@drawable/ic_notification',
              importance: targetChannel.importance,
              priority: isPromo ? Priority.defaultPriority : Priority.high,
              playSound: targetChannel.playSound,
              tag: isChat && orderId != null ? 'order_chat_$orderId' : null,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }

      if (onForegroundMessage != null) {
        onForegroundMessage(message);
      }
    });

    // 7. Handle notification click when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('App opened from notification: ${message.messageId}');
      }
      _handleTap(message.data);
    });

    // 7b. App was fully closed and opened by tapping a notification
    try {
      final initialMessage = await fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleTap(initialMessage.data);
      }
    } catch (_) {}

    // 8. Retrieve FCM registration token
    // ignore: deprecated_member_use
    fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      onTokenUpdated?.call(newToken);
      if (kDebugMode) {
        print('🔥 AGROKERA FCM TOKEN (refreshed): $newToken');
      }
    });

    await refreshToken();
  }

  /// Fetches the FCM registration token. Safe to call multiple times.
  String? lastError;

  Future<String?> refreshToken() async {
    final fcm = _fcm;
    if (fcm == null) return null;
    try {
      // ignore: deprecated_member_use
      final token = await fcm.getToken();
      if (token != null && token.isNotEmpty) {
        final changed = token != _fcmToken;
        _fcmToken = token;
        lastError = null;
        if (changed) onTokenUpdated?.call(token);
      }
      if (kDebugMode) {
        print('=============================================');
        print('🔥 AGROKERA FCM TOKEN:');
        print(_fcmToken);
        print('=============================================');
      }
    } catch (e) {
      lastError = e.toString();
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
    return _fcmToken;
  }
}
