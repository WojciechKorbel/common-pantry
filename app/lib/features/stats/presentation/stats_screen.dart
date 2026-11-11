import 'package:common_pantry/core/utils/responsive.dart';
import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/core/widgets/responsive_scaffold.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/stats/presentation/controllers/statistics_controller.dart';
import 'package:common_pantry/features/stats/presentation/widgets/statistics_category_list.dart';
import 'package:common_pantry/features/stats/presentation/widgets/statistics_period_selector.dart';
import 'package:common_pantry/features/stats/presentation/widgets/statistics_summary_card.dart';
import 'package:common_pantry/features/stats/presentation/widgets/statistics_timeline_chart.dart';
import 'package:common_pantry/features/stats/presentation/widgets/top_wasted_products_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.household,
    required this.controller,
  });

  final Household household;
  final StatisticsController controller;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildExpiryStatistics(
    int expired,
    int notExpired,
    ThemeData theme,
  ) {
    final total = expired + notExpired;
    final expiredPercentage = total == 0 ? 0.0 : expired / total;
    final notExpiredPercentage = total == 0 ? 0.0 : notExpired / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ExpiryValue(
                title: 'Expired',
                value: expired,
                color: theme.colorScheme.error,
              ),
            ),
            Expanded(
              child: _ExpiryValue(
                title: 'Not expired',
                value: notExpired,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Expanded(
                flex: expired > 0 ? expired : (notExpired > 0 ? 0 : 1),
                child: Container(
                  height: 12,
                  color: theme.colorScheme.error,
                ),
              ),
              Expanded(
                flex: notExpired > 0 ? notExpired : (expired > 0 ? 0 : 1),
                child: Container(
                  height: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Expired: ${(expiredPercentage * 100).toStringAsFixed(1)}%  •  '
          'Not expired: ${(notExpiredPercentage * 100).toStringAsFixed(1)}%',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildContent(StatisticsController controller) {
    final statistics = controller.statistics!;
    final summary = statistics.summary;
    final theme = Theme.of(context);

    final isWide =
        Responsive.isTablet(context) ||
        Responsive.isDesktop(context) ||
        (Responsive.isLandscape(context) && MediaQuery.sizeOf(context).width >= 600);

    final historySection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Food consumption history', theme),
        _sectionCard(
          child: StatisticsTimelineChart(
            entries: statistics.timeline,
            period: statistics.period,
          ),
        ),
      ],
    );

    final expirySection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Expiry statistics', theme),
        _sectionCard(
          child: _buildExpiryStatistics(
            statistics.expiry.expired,
            statistics.expiry.notExpired,
            theme,
          ),
        ),
      ],
    );

    final categoriesSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Waste by category', theme),
        _sectionCard(
          child: StatisticsCategoryList(
            categories: statistics.categories,
          ),
        ),
      ],
    );

    final topWastedSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Most wasted products', theme),
        _sectionCard(
          child: TopWastedProductsList(
            products: statistics.topWastedProducts,
          ),
        ),
      ],
    );

    final cardActive = StatisticsSummaryCard(
      title: 'Active',
      value: summary.activeCount,
      icon: Icons.inventory_2_outlined,
      color: Colors.blue,
    );
    final cardEaten = StatisticsSummaryCard(
      title: 'Eaten',
      value: summary.eatenCount,
      icon: Icons.restaurant_outlined,
      color: Colors.green,
    );
    final cardWasted = StatisticsSummaryCard(
      title: 'Wasted',
      value: summary.wastedCount,
      icon: Icons.delete_outline,
      color: theme.colorScheme.error,
    );
    final cardPercent = StatisticsSummaryCard(
      title: 'Waste percentage',
      value: summary.wastePercentage.round(),
      icon: Icons.pie_chart_outline,
      color: Colors.orange,
      subtitle: '% of closed products',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cardActive),
              const SizedBox(width: 8),
              Expanded(child: cardEaten),
              const SizedBox(width: 8),
              Expanded(child: cardWasted),
              const SizedBox(width: 8),
              Expanded(child: cardPercent),
            ],
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: cardActive),
                  const SizedBox(width: 8),
                  Expanded(child: cardEaten),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: cardWasted),
                  const SizedBox(width: 8),
                  Expanded(child: cardPercent),
                ],
              ),
            ],
          ),
        const SizedBox(height: 24),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    historySection,
                    const SizedBox(height: 24),
                    expirySection,
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    categoriesSection,
                    const SizedBox(height: 24),
                    topWastedSection,
                  ],
                ),
              ),
            ],
          )
        else ...[
          historySection,
          const SizedBox(height: 24),
          categoriesSection,
          const SizedBox(height: 24),
          topWastedSection,
          const SizedBox(height: 24),
          expirySection,
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveScaffold(
      household: widget.household,
      appBar: AppAppBar(
        title: widget.household.name,
        onBack: () => context.go('/households'),
        trailing: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => context.push('/settings'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final controller = widget.controller;

                if (controller.isLoading && !controller.hasLoaded) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (controller.errorMessage != null && !controller.hasLoaded) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bar_chart_outlined,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: controller.load,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: StatisticsPeriodSelector(
                        controller: controller,
                      ),
                    ),
                    if (controller.isLoading) const LinearProgressIndicator(),
                    if (controller.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          controller.errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: controller.refresh,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _buildContent(controller),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpiryValue extends StatelessWidget {
  const _ExpiryValue({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
