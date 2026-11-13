import 'dart:async';

import 'package:common_pantry/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService(this.api);

  final ApiClient api;
  StreamSubscription<String>? _registeredSubscription;
  String? _lastRegisteredToken;

  /// Registers the device in FCM and sends the token to Django via onRegistered.
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

    // Listen for token registration and automatic token rotations.
    _registeredSubscription ??= messaging.onRegistered.listen((token) async {
      _lastRegisteredToken = token;
      try {
        await _sendToken(token);
      } catch (e) {
        debugPrint('FCM token sync failed: $e');
      }
    });

    await messaging.register();
  }

  /// Unregisters the device in Django and removes the FCM registration on logout.
  Future<void> unregisterDevice() async {
    await _registeredSubscription?.cancel();
    _registeredSubscription = null;

    final messaging = FirebaseMessaging.instance;

    try {
      final token = _lastRegisteredToken;
      if (token != null && token.isNotEmpty) {
        await api.dio.delete<Object?>(
          '/api/devices/unregister/',
          data: {
            'fcm_token': token,
          },
          options: Options(contentType: Headers.jsonContentType),
        );
      }
    } catch (e) {
      debugPrint('FCM backend unregister failed: $e');
    } finally {
      _lastRegisteredToken = null;
    }

    try {
      await messaging.unregister();
    } catch (e) {
      debugPrint('FCM local unregister failed: $e');
    }
  }

  Future<void> _sendToken(String token) async {
    await api.dio.post<Object?>(
      '/api/devices/register/',
      data: {
        'fcm_token': token,
      },
    );
    debugPrint('FCM device registered successfully.');
  }

  Future<void> dispose() async {
    await _registeredSubscription?.cancel();
    _registeredSubscription = null;
  }
}
