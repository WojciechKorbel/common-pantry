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

  static StreamSubscription<String>? _globalRegisteredSub;
  static String? _latestToken;

  final ApiClient api;

  /// Call once in main.dart right after Firebase.initializeApp() so we never miss
  /// the initial FCM token emission.
  static Future<void> initListener() async {
    if (Firebase.apps.isEmpty || _globalRegisteredSub != null) {
      return;
    }

    _globalRegisteredSub = FirebaseMessaging.instance.onRegistered.listen(
      (token) async {
        if (token.isEmpty) return;
        _latestToken = token;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenPrefKey, token);
        } catch (_) {}
      },
    );

    try {
      await FirebaseMessaging.instance.register();
    } catch (e) {
      debugPrint('FCM initial register() notice: $e');
    }
  }

  Future<bool> isNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledPrefKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<String?> _getCachedToken() async {
    if (_latestToken != null && _latestToken!.isNotEmpty) {
      return _latestToken;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_tokenPrefKey);
      if (saved != null && saved.isNotEmpty) {
        _latestToken = saved;
      }
    } catch (_) {}
    return _latestToken;
  }

  Future<void> _saveCachedToken(String token) async {
    _latestToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenPrefKey, token);
    } catch (_) {}
  }

  Future<void> _clearCachedToken() async {
    _latestToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenPrefKey);
    } catch (_) {}
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledPrefKey, enabled);
    } catch (_) {}

    if (enabled) {
      await registerDevice();
    } else {
      await _unregisterFromBackendOnly();
    }
  }

  /// Registers the device in Django using the captured FCM token.
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

    var token = await _getCachedToken();

    if (token == null || token.isEmpty) {
      token = _latestToken;
    }

    if (token != null && token.isNotEmpty) {
      await _saveCachedToken(token);
      try {
        await _sendToken(token);
      } catch (e) {
        debugPrint('FCM device registration failed (401/Network): $e');
      }
      return;
    }

    final completer = Completer<String?>();
    final tempSub = messaging.onRegistered.listen((t) {
      if (t.isNotEmpty && !completer.isCompleted) {
        completer.complete(t);
      }
    });

    try {
      await messaging.register();
    } catch (e) {
      debugPrint('FCM register() error: $e');
    }

    try {
      token = await completer.future.timeout(const Duration(seconds: 4));
    } catch (_) {
      token = _latestToken;
    } finally {
      await tempSub.cancel();
    }

    if (token != null && token.isNotEmpty) {
      await _saveCachedToken(token);
      try {
        await _sendToken(token);
      } catch (e) {
        debugPrint('FCM device registration failed (401/Network): $e');
      }
    } else {
      debugPrint('FCM registration warning: Token is still null/empty.');
    }
  }

  Future<void> _unregisterFromBackendOnly() async {
    if (Firebase.apps.isEmpty) {
      return;
    }

    final token = await _getCachedToken();
    if (token != null && token.isNotEmpty) {
      try {
        await api.dio.delete<Object?>(
          '/api/devices/unregister/',
          data: {
            'fcm_token': token,
          },
          options: Options(contentType: Headers.jsonContentType),
        );
        debugPrint('FCM device unregistered from backend.');
      } catch (e) {
        debugPrint('FCM unregister failed: $e');
      }
    }
  }

  /// Full unregistration on logout: detaches token in Django and unregisters locally.
  Future<void> unregisterDevice() async {
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
}
