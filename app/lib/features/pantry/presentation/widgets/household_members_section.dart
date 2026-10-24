import 'package:common_pantry/features/pantry/data/models/household_details.dart';
import 'package:flutter/material.dart';

import 'household_member_tile.dart';

class HouseholdMembersSection extends StatelessWidget {
  const HouseholdMembersSection({
    super.key,
    required this.details,
    required this.isUpdating,
    required this.onMemberAction,
  });

  final HouseholdDetails details;
  final bool isUpdating;
  final void Function(HouseholdMember member, String action) onMemberAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Members',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            CircleAvatar(
              radius: 16,
              child: Text('${details.members.length}'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...details.members.map(
          (member) => HouseholdMemberTile(
            member: member,
            canManage: details.isOwner,
            isUpdating: isUpdating,
            onAction: (action) => onMemberAction(member, action),
          ),
        ),
      ],
    );
  }
}
