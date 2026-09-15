import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../infrastructure/api_client.dart';
import '../../infrastructure/app_logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Notification messages are shown by the system; nothing to do here.
}

/// Low-stock pushes, the nightly digest and upgrade notices from FCM.
/// Tapping a low-stock notification opens that product.
class MessagingService {
  final ApiClient api;
  final _openProduct = StreamController<String>.broadcast();
  final _notifications = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  MessagingService(this.api);

  /// Product uuids from tapped notifications.
  Stream<String> get productTaps => _openProduct.stream;

  bool get isReady => _ready;

  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  /// Safe to call without Firebase configured: messaging just stays off.
  Future<void> init() async {
    if (_ready || !isSupported) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      AppLogger.warning('Firebase not configured; push notifications disabled', e);
      return;
    }
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final uuid = response.payload;
        if (uuid != null && uuid.isNotEmpty) _openProduct.add(uuid);
      },
    );

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleTap(initial);
    _ready = true;
  }

  /// After login: ask permission, register the token, join the shop topic.
  Future<void> registerForShop(String shopId) async {
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await api.post('/device/register', {
          'token': token,
          'platform': Platform.operatingSystem,
        });
      }
      await FirebaseMessaging.instance.subscribeToTopic('shop_$shopId');
    } catch (e) {
      // Offline at login is normal; registration retries on next launch.
      AppLogger.warning('Push registration deferred', e);
    }
  }

  Future<void> unregisterFromShop(String shopId) async {
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('shop_$shopId');
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      AppLogger.warning('Push unregister failed', e);
    }
  }

  String? _pendingTap;

  /// A tap that launched the app arrives before anyone listens; hand it over once.
  String? takePendingTap() {
    final uuid = _pendingTap;
    _pendingTap = null;
    return uuid;
  }

  void _handleTap(RemoteMessage message) {
    final uuid = message.data['product_uuid'] as String?;
    if (uuid == null || uuid.isEmpty) return;
    if (_openProduct.hasListener) {
      _openProduct.add(uuid);
    } else {
      _pendingTap = uuid;
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _notifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'stock_alerts',
          'Stock alerts',
          channelDescription: 'Items running low and the daily digest',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['product_uuid'] as String?,
    );
  }
}
