import 'dart:async';

import 'package:common_pantry/core/network/api_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  NotificationService(this.api);

  final ApiClient api;
  StreamSubscription<String>? _tokenSubscription;

  // Register device in Django.
  Future<void> registerDevice() async {
    final messaging = FirebaseMessaging.instance;

    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await messaging.getToken();

    if (token != null) {
      await _sendToken(token);
    }

    // Listen for token changes.
    _tokenSubscription ??= messaging.onTokenRefresh.listen((newToken) {
      _sendToken(newToken);
    });

    // Notifications received while the app is open.
    FirebaseMessaging.onMessage.listen((message) {
      print('Notification received: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
    });
  }

  Future<void> _sendToken(String token) async {
    await api.dio.post(
      '/api/devices/register/',
      data: {
        'fcm_token': token,
      },
    );
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }
}

// Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  print('Background notification: ${message.messageId}');
}
