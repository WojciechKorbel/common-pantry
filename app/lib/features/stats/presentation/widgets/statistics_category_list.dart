import 'package:common_pantry/features/stats/data/models/food_waste_statistics.dart';
import 'package:common_pantry/features/stats/presentation/widgets/statistics_empty_state.dart';
import 'package:material_ui/material_ui.dart';

class StatisticsCategoryList extends StatelessWidget {
  const StatisticsCategoryList({
    super.key,
    required this.categories,
  });

  final List<WastedCategory> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const StatisticsEmptyState(
        title: 'No wasted products',
        message:
            'There are no wasted products in this period. '
            'Your category statistics will appear here.',
        icon: Icons.category_outlined,
      );
    }

    final theme = Theme.of(context);
    final maxValue = categories.first.wasted;

    return Column(
      children: categories.map((category) {
        final percentage = maxValue == 0 ? 0.0 : category.wasted / maxValue;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    category.wasted.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 9,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
