import 'package:flutter/material.dart';

class WorkoutEditorDialog extends StatelessWidget {
  const WorkoutEditorDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        title: Row(
          children: [
            Expanded(child: Text(title)),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(child: content),
        ),
        actions: actions,
      );
}
