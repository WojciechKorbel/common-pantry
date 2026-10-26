import 'package:common_pantry/core/theme/app_theme.dart';
import 'package:common_pantry/features/pantry/data/models/household_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HouseholdInfoCard extends StatefulWidget {
  const HouseholdInfoCard({
    super.key,
    required this.details,
    required this.isUpdating,
    required this.onSaveName,
  });

  final HouseholdDetails details;
  final bool isUpdating;
  final Future<bool> Function(String name) onSaveName;

  @override
  State<HouseholdInfoCard> createState() => _HouseholdInfoCardState();
}

class _HouseholdInfoCardState extends State<HouseholdInfoCard> {
  final _nameController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  String? _validationError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (!widget.details.isOwner || widget.isUpdating) return;

    setState(() {
      _nameController.text = widget.details.name;
      _validationError = null;
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    FocusScope.of(context).unfocus();

    setState(() {
      _isEditing = false;
      _validationError = null;
    });
  }

  Future<void> _saveName() async {
    if (_isSaving || widget.isUpdating) return;

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _validationError = 'A household name is required.';
      });
      return;
    }

    if (name == widget.details.name) {
      _cancelEditing();
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);

    try {
      final success = await widget.onSaveName(name);

      if (!mounted) return;

      if (success) {
        setState(() {
          _isEditing = false;
          _validationError = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _copyInviteCode() async {
    final code = widget.details.inviteCode;

    if (code.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final busy = widget.isUpdating || _isSaving;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.home_outlined, size: 36),
                const Spacer(),
                if (details.isOwner && !_isEditing)
                  IconButton(
                    tooltip: 'Edit household name',
                    onPressed: busy ? null : _startEditing,
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditing) ...[
              TextField(
                controller: _nameController,
                autofocus: true,
                maxLength: 100,
                enabled: !busy,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Household name',
                  errorText: _validationError,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_validationError != null) {
                    setState(() => _validationError = null);
                  }
                },
                onSubmitted: (_) => _saveName(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : _cancelEditing,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : _saveName,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ] else
              Text(
                details.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            const SizedBox(height: 8),
            Text(
              details.isOwner ? 'You are the owner' : 'You are a member',
              style: TextStyle(
                color: details.isOwner ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.vpn_key_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Invite code'),
                      const SizedBox(height: 4),
                      SelectableText(
                        details.inviteCode.isEmpty ? 'Unavailable' : details.inviteCode,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy invite code',
                  onPressed: details.inviteCode.isEmpty ? null : _copyInviteCode,
                  icon: const Icon(Icons.copy_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
