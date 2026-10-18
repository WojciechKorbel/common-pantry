import 'package:flutter/material.dart';

class AppHouseholdExpandableFab extends StatefulWidget {
  final VoidCallback onJoinHousehold;
  final VoidCallback onCreateHousehold;

  const AppHouseholdExpandableFab({
    super.key,
    required this.onJoinHousehold,
    required this.onCreateHousehold,
  });

  @override
  State<AppHouseholdExpandableFab> createState() => _AppExpandableFabState();
}

class _AppExpandableFabState extends State<AppHouseholdExpandableFab> {
  bool showOptions = false;

  void selectOption(VoidCallback callback) {
    setState(() {
      showOptions = false;
    });

    callback();
  }

  @override
  Widget build(BuildContext context) {
    final fabColor = Theme.of(context).colorScheme.primary;
    final fabForegroundColor = Theme.of(context).colorScheme.onPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showOptions)
          IntrinsicWidth(
            child: Material(
              color: fabColor,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      'Join household',
                      style: TextStyle(
                        color: fabForegroundColor,
                      ),
                    ),
                    trailing: Icon(
                      Icons.play_arrow,
                      color: fabForegroundColor,
                      size: 20,
                    ),
                    onTap: () => selectOption(
                      widget.onJoinHousehold,
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Create new household',
                      style: TextStyle(
                        color: fabForegroundColor,
                      ),
                    ),
                    trailing: Icon(
                      Icons.play_arrow,
                      color: fabForegroundColor,
                      size: 20,
                    ),
                    onTap: () => selectOption(
                      widget.onCreateHousehold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (showOptions) const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'mainfab',
          onPressed: () {
            setState(() {
              showOptions = !showOptions;
            });
          },
          backgroundColor: fabColor,
          foregroundColor: fabForegroundColor,
          child: Icon(
            showOptions ? Icons.close : Icons.add,
          ),
        ),
      ],
    );
  }
}