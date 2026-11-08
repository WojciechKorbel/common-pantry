import 'package:common_pantry/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ThemeController controller;
  late int notifications;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller = ThemeController();
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  Future<String?> storedMode() async =>
      (await SharedPreferences.getInstance()).getString('theme_mode');

  test('follows the system theme by default', () {
    expect(controller.themeMode, ThemeMode.system);
  });

  group('load', () {
    test('keeps the system theme when nothing was saved', () async {
      await controller.load();

      expect(controller.themeMode, ThemeMode.system);
      expect(notifications, 0);
    });

    for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
      test('restores the saved ${mode.name} mode', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': mode.name});

        await controller.load();

        expect(controller.themeMode, mode);
        expect(notifications, 1);
      });
    }

    test('falls back to the system theme for an unknown saved value', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});

      await controller.load();

      expect(controller.themeMode, ThemeMode.system);
    });
  });

  group('setThemeMode', () {
    test('changes the mode, notifies and saves it', () async {
      await controller.setThemeMode(ThemeMode.dark);

      expect(controller.themeMode, ThemeMode.dark);
      expect(notifications, 1);
      expect(await storedMode(), 'dark');
    });

    test('choosing the current mode does nothing', () async {
      await controller.setThemeMode(ThemeMode.system);

      expect(notifications, 0);
      expect(await storedMode(), isNull);
    });

    test('the last choice wins', () async {
      await controller.setThemeMode(ThemeMode.dark);
      await controller.setThemeMode(ThemeMode.light);

      expect(controller.themeMode, ThemeMode.light);
      expect(notifications, 2);
      expect(await storedMode(), 'light');
    });

    test('a new controller loads what the previous one saved', () async {
      await controller.setThemeMode(ThemeMode.dark);

      final next = ThemeController();
      addTearDown(next.dispose);
      await next.load();

      expect(next.themeMode, ThemeMode.dark);
    });
  });
}
