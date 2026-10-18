import 'package:common_pantry/features/households/presentation/controllers/join_household_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InviteCodeInput extends StatefulWidget {
  const InviteCodeInput({
    super.key,
    required this.controller,
    required this.hasError,
  });

  final JoinHouseholdController controller;
  final bool hasError;

  @override
  State<InviteCodeInput> createState() => _InviteCodeInputState();
}

class _InviteCodeInputState extends State<InviteCodeInput> {
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();

    _focusNodes = List.generate(
      JoinHouseholdController.codeLength,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  void _onDigitChanged(String value, int index) {
    widget.controller.onDigitChanged(value, index);

    if (value.isNotEmpty && index < JoinHouseholdController.codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  KeyEventResult _onFieldKey(
    FocusNode node,
    KeyEvent event,
    int index,
  ) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        widget.controller.codeControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: List.generate(
        JoinHouseholdController.codeLength,
        (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == JoinHouseholdController.codeLength - 1 ? 0 : 8,
              ),
              child: Focus(
                onKeyEvent: (node, event) => _onFieldKey(node, event, index),
                child: TextField(
                  controller: widget.controller.codeControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: index == JoinHouseholdController.codeLength - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  maxLength: 1,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: widget.hasError
                            ? theme.colorScheme.error
                            : theme.colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  onChanged: (value) => _onDigitChanged(value, index),
                  onSubmitted: (_) {
                    if (index == JoinHouseholdController.codeLength - 1) {
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
