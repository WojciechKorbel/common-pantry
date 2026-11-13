import 'dart:async';

import 'package:common_pantry/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService(this.api);

  static const String _enabledPrefKey = 'expiry_notifications_enabled';
  static const String _tokenPrefKey = 'cached_fcm_token';

  final ApiClient api;
  StreamSubscription<String>? _registeredSubscription;
  String? _lastRegisteredToken;

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledPrefKey) ?? true;
  }

  Future<String?> _getCachedToken() async {
    if (_lastRegisteredToken != null && _lastRegisteredToken!.isNotEmpty) {
      return _lastRegisteredToken;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenPrefKey);
    if (saved != null && saved.isNotEmpty) {
      _lastRegisteredToken = saved;
    }
    return _lastRegisteredToken;
  }

  Future<void> _saveCachedToken(String token) async {
    _lastRegisteredToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefKey, token);
  }

  Future<void> _clearCachedToken() async {
    _lastRegisteredToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefKey);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledPrefKey, enabled);

    if (enabled) {
      await registerDevice();
    } else {
      await _unregisterFromBackendOnly();
    }
  }

  /// Registers the device in FCM and sends the token to Django via onRegistered.
  Future<void> registerDevice() async {
    if (Firebase.apps.isEmpty) {
      return;
    }

    if (!await isNotificationsEnabled()) {
      return;
    }

    final messaging = FirebaseMessaging.instance;

    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    _registeredSubscription ??= messaging.onRegistered.listen((token) async {
      await _saveCachedToken(token);
      try {
        await _sendToken(token);
      } catch (e) {
        debugPrint('FCM token sync failed: $e');
      }
    });

    final existingToken = await _getCachedToken();
    if (existingToken != null && existingToken.isNotEmpty) {
      await _sendToken(existingToken);
      return;
    }

    try {
      await messaging.register();
    } catch (e) {
      debugPrint('FCM messaging.register() error: $e');
    }
  }

  /// Unregisters the token in Django when the user disables notifications in Settings,
  /// keeping the local FCM token intact so re-enabling is instant and reliable.
  Future<void> _unregisterFromBackendOnly() async {
    if (Firebase.apps.isEmpty) {
      return;
    }

    final token = await _getCachedToken();
    if (token != null && token.isNotEmpty) {
      await api.dio.delete<Object?>(
        '/api/devices/unregister/',
        data: {
          'fcm_token': token,
        },
        options: Options(contentType: Headers.jsonContentType),
      );
    }
  }

  /// Full unregistration on logout: detaches token in Django and removes FCM registration.
  Future<void> unregisterDevice() async {
    await _registeredSubscription?.cancel();
    _registeredSubscription = null;

    if (Firebase.apps.isEmpty) {
      await _clearCachedToken();
      return;
    }

    final messaging = FirebaseMessaging.instance;

    try {
      final token = await _getCachedToken();
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
      await _clearCachedToken();
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
