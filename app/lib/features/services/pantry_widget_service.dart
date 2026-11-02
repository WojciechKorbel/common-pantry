import 'package:common_pantry/features/pantry/data/models/pantry_group.dart';
import 'package:common_pantry/features/pantry/domain/expiry_status.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class PantryWidgetService {
  static const String _androidWidgetName = 'PantryWidgetProvider';

  static Future<void> updateThemeMode(ThemeMode mode) async {
    await HomeWidget.saveWidgetData<String>('theme_mode', mode.name);
    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
    );
  }

  static Future<void> updateWidget({
    required String householdName,
    required List<PantryGroup> groups,
  }) async {
    final now = DateTime.now();

    final urgentGroups = groups.where((g) {
      if (g.expiryStatus != null) {
        return g.expiryStatus == 'soon' || g.expiryStatus == 'expired';
      }
      final status = expiryStatusOf(g.earliestExpiry, now);
      return status == ExpiryStatus.soon || status == ExpiryStatus.expired;
    }).toList();

    final count = urgentGroups.fold<int>(0, (sum, g) => sum + g.itemCount);

    String headline = 'All items are fresh!';
    if (urgentGroups.isNotEmpty) {
      final first = urgentGroups.first;
      headline = 'Expiring: ${first.name} (${first.itemCount}x)';
    }

    await HomeWidget.saveWidgetData<String>('household_name', householdName);
    await HomeWidget.saveWidgetData<int>('expiring_count', count);
    await HomeWidget.saveWidgetData<String>('headline', headline);

    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
