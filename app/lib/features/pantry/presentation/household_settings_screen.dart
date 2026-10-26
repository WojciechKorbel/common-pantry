import 'package:common_pantry/core/di/dependencies.dart';
import 'package:common_pantry/core/widgets/app_app_bar.dart';
import 'package:common_pantry/core/widgets/app_bottom_navigation_bar.dart';
import 'package:common_pantry/features/households/data/models/household.dart';
import 'package:common_pantry/features/pantry/data/models/household_details.dart';
import 'package:common_pantry/features/pantry/presentation/controllers/household_details_controller.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/household_info_card.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/household_members_section.dart';
import 'package:common_pantry/features/pantry/presentation/widgets/leave_household_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HouseholdSettingsScreen extends StatefulWidget {
  const HouseholdSettingsScreen({
    super.key,
    required this.household,
    required this.controller,
  });

  final Household household;
  final HouseholdDetailsController controller;

  @override
  State<HouseholdSettingsScreen> createState() => _HouseholdSettingsScreenState();
}

class _HouseholdSettingsScreenState extends State<HouseholdSettingsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<void> _handleMemberAction(
    HouseholdMember member,
    String action,
  ) async {
    final controller = widget.controller;

    if (controller.isUpdating) return;

    final title = switch (action) {
      'promote' => 'Promote to owner?',
      'demote' => 'Demote to member?',
      _ => 'Remove member?',
    };

    final message = switch (action) {
      'promote' => 'Give ${member.username} owner permissions for this household?',
      'demote' => 'Remove owner permissions from ${member.username}?',
      _ => 'Remove ${member.username} from this household?',
    };

    final confirmed = await _confirm(
      title: title,
      message: message,
      confirmLabel: action == 'remove' ? 'Remove' : 'Confirm',
      destructive: action == 'remove' || action == 'demote',
    );

    if (!confirmed || !mounted) return;

    final success = switch (action) {
      'promote' => await controller.promoteMember(member.userId),
      'demote' => await controller.demoteMember(member.userId),
      _ => await controller.removeMember(member.userId),
    };

    if (!mounted) return;

    _showMessage(
      success
          ? switch (action) {
              'promote' => '${member.username} is now an owner.',
              'demote' => '${member.username} is now a member.',
              _ => '${member.username} was removed.',
            }
          : controller.errorMessage ?? 'Failed to update household members.',
    );
  }

  bool _isLastOwner(HouseholdDetails details) {
    return details.isOwner &&
        details.members.length > 1 &&
        !details.members.any(
          (member) => member.isOwner && !member.isMe,
        );
  }

  Future<void> _leaveHousehold(
    HouseholdDetails details,
  ) async {
    final controller = widget.controller;

    if (controller.isUpdating) return;

    if (_isLastOwner(details)) {
      _showMessage(
        'Promote another member to owner before leaving this household.',
      );
      return;
    }

    final confirmed = await _confirm(
      title: 'Leave household?',
      message: details.members.length == 1
          ? 'You are the last member. Leaving will permanently delete '
                'this household and all its shared pantry data. '
                'This action cannot be undone.'
          : 'You will lose access to this household and its shared pantry.',
      confirmLabel: 'Leave',
      destructive: true,
    );

    if (!confirmed || !mounted) return;

    final success = await controller.leaveHousehold();

    if (!mounted) return;

    if (!success) {
      _showMessage(
        controller.errorMessage ?? 'Failed to leave household.',
      );
      return;
    }

    _showMessage('You have left the household.');

    context.go('/households');
  }

  Widget _buildThemeSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Choose app theme mode',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: Dependencies.themeController,
              builder: (context, _) {
                final currentMode = Dependencies.themeController.themeMode;

                return SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {currentMode},
                    onSelectionChanged: (selected) {
                      Dependencies.themeController.setThemeMode(selected.first);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(
        title: 'Household details',
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        household: widget.household,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, child) {
            final controller = widget.controller;
            final details = controller.details;

            if (controller.isLoading && details == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (controller.errorMessage != null && details == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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

            if (details == null) {
              return const Center(
                child: Text(
                  'No household details available.',
                ),
              );
            }

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      HouseholdInfoCard(
                        details: details,
                        isUpdating: controller.isUpdating,
                        onSaveName: (name) async {
                          final success = await controller.updateHouseholdName(
                            name,
                          );

                          if (!mounted) return false;

                          _showMessage(
                            success
                                ? 'Household name updated.'
                                : controller.errorMessage ?? 'Failed to update household name.',
                          );

                          return success;
                        },
                      ),
                      const SizedBox(height: 24),
                      HouseholdMembersSection(
                        details: details,
                        isUpdating: controller.isUpdating,
                        onMemberAction: _handleMemberAction,
                      ),
                      const SizedBox(height: 24),
                      _buildThemeSelector(context),
                      const SizedBox(height: 24),
                      LeaveHouseholdButton(
                        isUpdating: controller.isUpdating,
                        onPressed: () => _leaveHousehold(details),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                if (controller.isUpdating)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
