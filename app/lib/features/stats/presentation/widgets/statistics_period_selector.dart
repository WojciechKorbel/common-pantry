import 'package:common_pantry/features/stats/presentation/controllers/statistics_controller.dart';
import 'package:material_ui/material_ui.dart';

class StatisticsPeriodSelector extends StatelessWidget {
  const StatisticsPeriodSelector({
    super.key,
    required this.controller,
  });

  final StatisticsController controller;

  String _periodLabel(String period) {
    return switch (period) {
      '7d' => '7 days',
      '30d' => '30 days',
      '12m' => '12 months',
      'all' => 'All time',
      _ => period,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics period',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: StatisticsController.periods.map((period) {
            return ChoiceChip(
              label: Text(_periodLabel(period)),
              selected: controller.period == period,
              onSelected: controller.isLoading ? null : (_) => controller.setPeriod(period),
            );
          }).toList(),
        ),
      ],
    );
  }
}
