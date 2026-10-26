import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/pantry/data/models/household_details.dart';
import 'package:flutter/material.dart';

class HouseholdMemberTile extends StatelessWidget {
  const HouseholdMemberTile({
    super.key,
    required this.member,
    required this.canManage,
    required this.isUpdating,
    required this.onAction,
  });

  final HouseholdMember member;
  final bool canManage;
  final bool isUpdating;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            member.username.isNotEmpty ? member.username[0].toUpperCase() : '?',
          ),
        ),
        title: Text(
          member.isMe ? '${member.username} (you)' : member.username,
        ),
        subtitle: Text(member.isOwner ? 'Owner' : 'Member'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              member.isOwner ? Icons.verified_user_outlined : Icons.person_outline,
              color: member.isOwner ? AppColors.primary : null,
            ),
            if (canManage && !member.isMe)
              PopupMenuButton<String>(
                tooltip: 'Manage member',
                enabled: !isUpdating,
                onSelected: onAction,
                itemBuilder: (context) => [
                  if (!member.isOwner)
                    const PopupMenuItem(
                      value: 'promote',
                      child: Text('Promote to owner'),
                    ),
                  if (member.isOwner)
                    const PopupMenuItem(
                      value: 'demote',
                      child: Text('Demote to member'),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove member'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
