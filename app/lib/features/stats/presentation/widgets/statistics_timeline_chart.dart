import 'dart:math' as math;

import 'package:common_pantry/features/stats/data/models/food_waste_statistics.dart';
import 'package:common_pantry/features/stats/presentation/widgets/statistics_empty_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

class StatisticsTimelineChart extends StatelessWidget {
  const StatisticsTimelineChart({
    super.key,
    required this.entries,
    required this.period,
  });

  final List<StatisticsTimelineEntry> entries;
  final String period;

  static const eatenColor = Color(0xFF43A876);

  bool get _isScrollable => period == '12m' || period == 'all';

  String _formatDate(DateTime date) {
    if (_isScrollable) {
      return '${date.month.toString().padLeft(2, '0')}/'
          '${date.year.toString().substring(2)}';
    }

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}';
  }

  bool _shouldShowLabel(int index) {
    if (period == '7d') return true;

    if (period == '12m') return true;

    if (period == 'all') {
      return index % 2 == 0 || index == entries.length - 1;
    }

    return index % 5 == 0 || index == entries.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wastedColor = theme.colorScheme.error;

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

    final maxValue = entries.fold<int>(
      0,
      (max, entry) {
        final total = entry.eaten + entry.wasted;
        return total > max ? total : max;
      },
    );

    final interval = maxValue <= 4 ? 1.0 : (maxValue / 4).ceilToDouble();

    final barWidth = _isScrollable ? 12.0 : 8.0;
    const barsSpace = 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _Legend(
              color: eatenColor,
              label: 'Eaten',
            ),
            const SizedBox(width: 20),
            _Legend(
              color: wastedColor,
              label: 'Wasted',
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_isScrollable)
          _buildScrollableChart(
            context,
            interval,
            maxValue,
            barWidth,
            barsSpace,
          )
        else
          SizedBox(
            height: 240,
            child: _buildChart(
              context,
              interval,
              maxValue,
              barWidth,
              barsSpace,
            ),
          ),

        if (_isScrollable && entries.length > 6) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swipe,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Swipe horizontally to explore history',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildScrollableChart(
    BuildContext context,
    double interval,
    int maxValue,
    double barWidth,
    double barsSpace,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const axisWidth = 40.0;
        const monthWidth = 65.0;
        const chartHeight = 260.0;

        final availableWidth = constraints.maxWidth - axisWidth;

        final chartWidth = math.max(
          availableWidth,
          entries.length * monthWidth,
        );

        final maxY = maxValue == 0 ? 1.0 : maxValue + interval;

        final labelCount = (maxY / interval).ceil();

        return SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed Y axis.
              SizedBox(
                width: axisWidth,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 4,
                    bottom: 36,
                    right: 6,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      labelCount + 1,
                      (index) {
                        final value = (labelCount - index) * interval;

                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Scrollable chart.
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    height: chartHeight,
                    child: _buildChart(
                      context,
                      interval,
                      maxValue,
                      barWidth,
                      barsSpace,
                      hideLeftTitles: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart(
    BuildContext context,
    double interval,
    int maxValue,
    double barWidth,
    double barsSpace, {
    bool hideLeftTitles = false,
  }) {
    final theme = Theme.of(context);
    final wastedColor = theme.colorScheme.error;

    return BarChart(
      BarChartData(
        maxY: maxValue == 0 ? 1 : maxValue + interval,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        groupsSpace: 8,

        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final index = group.x.toInt();

              if (index < 0 || index >= entries.length) {
                return null;
              }

              final entry = entries[index];

              return BarTooltipItem(
                '${_formatDate(entry.date)}\n',
                const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: 'Eaten: ${entry.eaten}\n',
                    style: const TextStyle(
                      color: eatenColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: 'Wasted: ${entry.wasted}',
                    style: TextStyle(
                      color: wastedColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.dividerColor.withValues(alpha: 0.35),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
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
              showTitles: !hideLeftTitles,
              reservedSize: hideLeftTitles ? 0 : 34,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                if (index < 0 || index >= entries.length || !_shouldShowLabel(index)) {
                  return const SizedBox.shrink();
                }

                return SideTitleWidget(
                  meta: meta,
                  space: 10,
                  child: Text(
                    _formatDate(entries[index].date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
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
            barsSpace: barsSpace,
            barRods: [
              BarChartRodData(
                toY: entry.eaten.toDouble(),
                color: eatenColor,
                width: barWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
              ),
              BarChartRodData(
                toY: entry.wasted.toDouble(),
                color: wastedColor,
                width: barWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
              ),
            ],
          );
        }),
      ),
      duration: const Duration(milliseconds: 300),
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
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
