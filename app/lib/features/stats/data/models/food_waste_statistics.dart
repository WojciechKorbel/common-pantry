class FoodWasteStatistics {
  const FoodWasteStatistics({
    required this.period,
    required this.summary,
    required this.timeline,
    required this.categories,
    required this.topWastedProducts,
    required this.expiry,
  });

  final String period;
  final StatisticsSummary summary;
  final List<StatisticsTimelineEntry> timeline;
  final List<WastedCategory> categories;
  final List<TopWastedProduct> topWastedProducts;
  final ExpiryStatistics expiry;

  factory FoodWasteStatistics.fromJson(Map<String, dynamic> json) {
    return FoodWasteStatistics(
      period: json['period'] as String,
      summary: StatisticsSummary.fromJson(
        Map<String, dynamic>.from(json['summary'] as Map),
      ),
      timeline: (json['timeline'] as List<dynamic>)
          .map(
            (e) => StatisticsTimelineEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      categories: (json['categories'] as List<dynamic>)
          .map(
            (e) => WastedCategory.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      topWastedProducts: (json['top_wasted_products'] as List<dynamic>)
          .map(
            (e) => TopWastedProduct.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      expiry: ExpiryStatistics.fromJson(
        Map<String, dynamic>.from(json['expiry'] as Map),
      ),
    );
  }
}

class StatisticsSummary {
  const StatisticsSummary({
    required this.activeCount,
    required this.eatenCount,
    required this.wastedCount,
    required this.wastePercentage,
  });

  final int activeCount;
  final int eatenCount;
  final int wastedCount;
  final double wastePercentage;

  int get closedCount => eatenCount + wastedCount;

  factory StatisticsSummary.fromJson(Map<String, dynamic> json) {
    return StatisticsSummary(
      activeCount: (json['active_count'] as num).toInt(),
      eatenCount: (json['eaten_count'] as num).toInt(),
      wastedCount: (json['wasted_count'] as num).toInt(),
      wastePercentage: (json['waste_percentage'] as num).toDouble(),
    );
  }
}

class StatisticsTimelineEntry {
  const StatisticsTimelineEntry({
    required this.date,
    required this.eaten,
    required this.wasted,
  });

  final DateTime date;
  final int eaten;
  final int wasted;

  factory StatisticsTimelineEntry.fromJson(Map<String, dynamic> json) {
    return StatisticsTimelineEntry(
      date: DateTime.parse(
        (json['date'] as String).substring(0, 10),
      ),
      eaten: (json['eaten'] as num).toInt(),
      wasted: (json['wasted'] as num).toInt(),
    );
  }
}

class WastedCategory {
  const WastedCategory({
    required this.name,
    required this.wasted,
  });

  final String name;
  final int wasted;

  factory WastedCategory.fromJson(Map<String, dynamic> json) {
    return WastedCategory(
      name: json['name'] as String,
      wasted: (json['wasted'] as num).toInt(),
    );
  }
}

class TopWastedProduct {
  const TopWastedProduct({
    required this.name,
    this.brand,
    required this.count,
  });

  final String name;
  final String? brand;
  final int count;

  factory TopWastedProduct.fromJson(Map<String, dynamic> json) {
    return TopWastedProduct(
      name: json['name'] as String,
      brand: json['brand'] as String?,
      count: (json['count'] as num).toInt(),
    );
  }
}

class ExpiryStatistics {
  const ExpiryStatistics({
    required this.expired,
    required this.notExpired,
  });

  final int expired;
  final int notExpired;

  factory ExpiryStatistics.fromJson(Map<String, dynamic> json) {
    return ExpiryStatistics(
      expired: (json['expired'] as num).toInt(),
      notExpired: (json['not_expired'] as num).toInt(),
    );
  }

  int get total => expired + notExpired;
}
