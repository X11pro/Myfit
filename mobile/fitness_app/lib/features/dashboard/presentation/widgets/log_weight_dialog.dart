import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/app_language.dart';
import '../../application/daily_weight_controller.dart';

Future<void> showLogWeightDialog(
    BuildContext context, WidgetRef ref, AppStrings strings) async {
  final entries = ref.read(dailyWeightEntriesProvider.notifier);
  var value = ref.read(todayWeightEntryProvider)?.weightKg.toString() ?? '';
  String? error;
  var submitted = false;
  final weight = await showDialog<double>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        void submit() {
          if (submitted) return;
          final weight = double.tryParse(value.trim().replaceAll(',', '.'));
          if (weight == null || !weight.isFinite || weight <= 0) {
            setDialogState(() => error = strings.invalidWeightMessage);
            return;
          }
          submitted = true;
          Navigator.pop(context, weight);
        }

        return AlertDialog(
          title: Text(strings.logWeightTitle),
          content: TextFormField(
            initialValue: value,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: strings.weightInputLabel, errorText: error),
            onChanged: (input) => value = input,
            onFieldSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.cancelButton),
            ),
            FilledButton(
              onPressed: submit,
              child: Text(strings.saveWeightButton),
            ),
          ],
        );
      },
    ),
  );
  if (weight == null || !context.mounted) return;
  try {
    await entries.upsertTodayWeight(weight);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.weightSavedMessage)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.remoteSaveFailedMessage)));
    }
  }
}
