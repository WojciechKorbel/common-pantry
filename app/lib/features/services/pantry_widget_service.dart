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
    final today = DateTime(now.year, now.month, now.day);

    final totalItemsCount = groups.fold<int>(0, (sum, g) => sum + g.itemCount);

    final List<PantryGroup> expiredGroups = [];
    final List<PantryGroup> soonGroups = [];

    for (final group in groups) {
      String? status = group.expiryStatus;
      if (status == null) {
        final calcStatus = expiryStatusOf(group.earliestExpiry, now);
        status = calcStatus.name;
      }

      if (status == 'expired') {
        expiredGroups.add(group);
      } else if (status == 'soon') {
        soonGroups.add(group);
      }
    }

    final expiredCount = expiredGroups.fold<int>(0, (sum, g) => sum + g.itemCount);
    final soonCount = soonGroups.fold<int>(0, (sum, g) => sum + g.itemCount);

    String statusType = 'fresh';
    String countHeader = 'All fresh!';

    if (totalItemsCount == 0) {
      statusType = 'empty';
      countHeader = 'No items yet';
    } else if (expiredCount > 0 && soonCount > 0) {
      statusType = 'expired';
      countHeader = '$expiredCount expired, $soonCount soon';
    } else if (expiredCount > 0) {
      statusType = 'expired';
      countHeader = '$expiredCount expired';
    } else if (soonCount > 0) {
      statusType = 'soon';
      countHeader = '$soonCount expiring soon';
    } else {
      statusType = 'fresh';
      countHeader = 'All fresh!';
    }

    final allPriorityGroups = [...expiredGroups, ...soonGroups];

    final List<String> listLines = [];
    if (statusType == 'empty') {
      listLines.add('Your pantry is empty.');
      listLines.add('Add items to track expiration.');
    } else if (allPriorityGroups.isEmpty) {
      listLines.add('Everything is fresh and good to go!');
    } else {
      final topGroups = allPriorityGroups.take(5).toList();

      for (final g in topGroups) {
        final expDate = DateTime(
          g.earliestExpiry.year,
          g.earliestExpiry.month,
          g.earliestExpiry.day,
        );
        final diff = expDate.difference(today).inDays;

        String timeInfo;
        if (diff < 0) {
          final daysAgo = diff.abs();
          timeInfo = daysAgo == 1 ? ' · yesterday' : ' · $daysAgo d ago';
        } else if (diff == 0) {
          timeInfo = ' · today';
        } else if (diff == 1) {
          timeInfo = ' · tomorrow';
        } else {
          timeInfo = ' · in $diff d';
        }

        listLines.add('• ${g.name} (${g.itemCount}x)$timeInfo');
      }

      final remaining = allPriorityGroups.length - topGroups.length;
      if (remaining > 0) {
        listLines.add('… and $remaining more');
      }
    }

    final bodyMessage = listLines.join('\n');
    final footerInfo = totalItemsCount > 0
        ? '$totalItemsCount total items in pantry'
        : 'Common Pantry';

    await HomeWidget.saveWidgetData<String>('household_name', householdName);
    await HomeWidget.saveWidgetData<String>('count_header', countHeader);
    await HomeWidget.saveWidgetData<String>('status_type', statusType);
    await HomeWidget.saveWidgetData<String>('body_message', bodyMessage);
    await HomeWidget.saveWidgetData<String>('footer_info', footerInfo);

    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
