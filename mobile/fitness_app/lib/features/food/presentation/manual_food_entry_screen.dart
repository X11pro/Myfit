import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_language.dart';
import '../application/manual_food_entries_controller.dart';

class ManualFoodEntryScreen extends ConsumerStatefulWidget {
  const ManualFoodEntryScreen({super.key});

  @override
  ConsumerState<ManualFoodEntryScreen> createState() =>
      _ManualFoodEntryScreenState();
}

class _ManualFoodEntryScreenState extends ConsumerState<ManualFoodEntryScreen> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  String _mealType = 'breakfast';

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(ref);

    return Scaffold(
      appBar: AppBar(title: Text(strings.addMealTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            strings.addMealSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: strings.foodNameLabel),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _mealType,
            decoration: InputDecoration(labelText: strings.mealTypeLabel),
            items: [
              DropdownMenuItem(
                value: 'breakfast',
                child: Text(strings.mealTypeBreakfast),
              ),
              DropdownMenuItem(
                value: 'lunch',
                child: Text(strings.mealTypeLunch),
              ),
              DropdownMenuItem(
                value: 'dinner',
                child: Text(strings.mealTypeDinner),
              ),
              DropdownMenuItem(
                value: 'snack',
                child: Text(strings.mealTypeSnack),
              ),
            ],
            onChanged: (value) =>
                setState(() => _mealType = value ?? _mealType),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caloriesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: strings.caloriesLabel),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _proteinController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: strings.proteinLabel),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(strings.saveMealButton),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final strings = stringsFor(ref);
    final name = _nameController.text.trim();
    final calories = int.tryParse(_caloriesController.text.trim());
    final protein = int.tryParse(_proteinController.text.trim());

    if (name.isEmpty || calories == null || protein == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.invalidMealMessage)),
      );
      return;
    }

    ref.read(manualFoodEntriesProvider.notifier).addEntry(
          name: name,
          mealType: _mealType,
          calories: calories,
          proteinGrams: protein,
        );

    context.go('/dashboard');
  }
}
