import 'package:flutter/material.dart';

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          if (accent != null) ...[
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: 28,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
