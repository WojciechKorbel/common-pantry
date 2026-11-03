import 'package:common_pantry/features/stats/data/models/food_waste_statistics.dart';
import 'package:common_pantry/features/stats/presentation/widgets/statistics_empty_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatisticsTimelineChart extends StatelessWidget {
  const StatisticsTimelineChart({
    super.key,
    required this.entries,
    required this.period,
  });

  final List<StatisticsTimelineEntry> entries;
  final String period;

  String _formatDate(DateTime date) {
    if (period == '12m') {
      return '${date.month.toString().padLeft(2, '0')}/${date.year % 100}';
    }

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasData = entries.any(
      (entry) => entry.eaten > 0 || entry.wasted > 0,
    );

    if (!hasData) {
      return const StatisticsEmptyState(
        title: 'No consumption history',
        message:
            'There is no food consumption data for this period. '
            'Start marking products as eaten or wasted to see your history.',
        icon: Icons.show_chart,
      );
    }

    const eatenColor = Colors.green;
    final wastedColor = theme.colorScheme.error;

    final maxValue = entries.fold<int>(
      0,
      (max, entry) {
        final total = entry.eaten + entry.wasted;
        return total > max ? total : max;
      },
    );

    final interval = maxValue <= 4 ? 1.0 : (maxValue / 4).ceilToDouble();

    final labelIndexes = <int>{
      0,
      entries.length - 1,
      if (entries.length > 2) entries.length ~/ 2,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _Legend(color: eatenColor, label: 'Eaten'),
            const SizedBox(width: 16),
            _Legend(color: wastedColor, label: 'Wasted'),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxValue == 0 ? 1 : maxValue + interval,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 12,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final entry = entries[group.x.toInt()];
                    final label = rodIndex == 0 ? 'Eaten' : 'Wasted';
                    final value = rodIndex == 0 ? entry.eaten : entry.wasted;

                    return BarTooltipItem(
                      '$label: $value',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: interval,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < 0 || index >= entries.length || !labelIndexes.contains(index)) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _formatDate(entries[index].date),
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(entries.length, (index) {
                final entry = entries[index];

                return BarChartGroupData(
                  x: index,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: entry.eaten.toDouble(),
                      color: eatenColor,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: entry.wasted.toDouble(),
                      color: wastedColor,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
