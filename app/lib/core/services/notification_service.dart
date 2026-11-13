import 'dart:async';

import 'package:common_pantry/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService(this.api);

  final ApiClient api;
  StreamSubscription<String>? _tokenSubscription;

  /// Registers the current device's FCM token in Django for the logged-in user.
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

    // Re-register automatically if FCM rotates the token while logged in.
    _tokenSubscription ??= messaging.onTokenRefresh.listen((newToken) async {
      try {
        await _sendToken(newToken);
      } catch (e) {
        debugPrint('FCM token refresh sync failed: $e');
      }
    });
  }

  /// Unregisters the device in Django and deletes the local FCM token on logout.
  Future<void> unregisterDevice() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;

    final messaging = FirebaseMessaging.instance;

    try {
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await api.dio.delete(
          '/api/devices/unregister/',
          data: {
            'fcm_token': token,
          },
          options: Options(contentType: Headers.jsonContentType),
        );
      }
    } catch (e) {
      // Logout must proceed even if offline or token already expired.
      debugPrint('FCM backend unregister failed: $e');
    }

    try {
      await messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM local deleteToken failed: $e');
    }
  }

  Future<void> _sendToken(String token) async {
    await api.dio.post(
      '/api/devices/register/',
      data: {
        'fcm_token': token,
      },
    );
    debugPrint('FCM device registered successfully.');
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }
}
