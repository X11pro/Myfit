import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/app_language.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../application/manual_food_entries_controller.dart';
import '../domain/manual_food_entry.dart';

class ManualFoodEntryScreen extends ConsumerStatefulWidget {
  const ManualFoodEntryScreen({super.key, this.entry});

  final ManualFoodEntry? entry;

  @override
  ConsumerState<ManualFoodEntryScreen> createState() =>
      _ManualFoodEntryScreenState();
}

class _ManualFoodEntryScreenState extends ConsumerState<ManualFoodEntryScreen> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _sugarController = TextEditingController();
  final _fiberController = TextEditingController();
  String _mealType = 'breakfast';
  String? _photoPath;
  bool _isAnalyzing = false;
  double? _confidence;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();

    final entry = widget.entry;
    if (entry == null) {
      return;
    }

    _nameController.text = entry.name;
    _caloriesController.text = entry.calories.toString();
    _proteinController.text = entry.proteinGrams.toString();
    _carbsController.text = entry.carbsGrams.toString();
    _fatController.text = entry.fatGrams.toString();
    _sugarController.text = entry.sugarGrams.toString();
    _fiberController.text = entry.fiberGrams.toString();
    _mealType = entry.mealType;
    _photoPath = entry.photoPath;
    _confidence = entry.confidence;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _sugarController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(ref);

    return Scaffold(
      appBar: AppTopBar(
        title: _isEditing ? strings.editMealTitle : strings.addMealTitle,
        strings: strings,
      ),
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
          const SizedBox(height: 16),
          TextField(
            controller: _carbsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: strings.carbsLabel),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fatController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: strings.fatLabel),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sugarController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: strings.sugarLabel),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fiberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: strings.fiberLabel),
          ),
          if (_confidence != null) ...[
            const SizedBox(height: 16),
            Text(
              '${strings.confidence}: ${(_confidence! * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          Text(strings.mealPhotoLabel,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_photoPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_photoPath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(strings.noMealsYet),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed:
                    _isAnalyzing ? null : () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(
                  _photoPath == null
                      ? strings.addPhotoButton
                      : strings.changePhotoButton,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed:
                    _isAnalyzing ? null : () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(strings.choosePhotoButton),
              ),
              if (_photoPath != null)
                OutlinedButton(
                  onPressed: () => setState(() => _photoPath = null),
                  child: Text(strings.removePhotoButton),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeWithAi,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(
                _isAnalyzing
                    ? '${strings.analyzeWithAiButton}...'
                    : strings.analyzeWithAiButton,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(
                _isEditing ? strings.updateMealButton : strings.saveMealButton,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final strings = stringsFor(ref);
    final name = _nameController.text.trim();
    final calories = int.tryParse(_caloriesController.text.trim());
    final protein = int.tryParse(_proteinController.text.trim());
    final carbs = int.tryParse(_carbsController.text.trim()) ?? 0;
    final fat = int.tryParse(_fatController.text.trim()) ?? 0;
    final sugar = int.tryParse(_sugarController.text.trim()) ?? 0;
    final fiber = int.tryParse(_fiberController.text.trim()) ?? 0;

    if (name.isEmpty || calories == null || protein == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.invalidMealMessage)),
      );
      return;
    }

    final notifier = ref.read(manualFoodEntriesProvider.notifier);

    if (_isEditing) {
      await notifier.updateEntry(
        id: widget.entry!.id,
        name: name,
        mealType: _mealType,
        calories: calories,
        proteinGrams: protein,
        carbsGrams: carbs,
        fatGrams: fat,
        sugarGrams: sugar,
        fiberGrams: fiber,
        confidence: _confidence,
        photoPath: _photoPath,
      );
    } else {
      await notifier.addEntry(
        name: name,
        mealType: _mealType,
        calories: calories,
        proteinGrams: protein,
        carbsGrams: carbs,
        fatGrams: fat,
        sugarGrams: sugar,
        fiberGrams: fiber,
        confidence: _confidence,
        photoPath: _photoPath,
      );
    }

    if (!mounted) {
      return;
    }

    context.go('/dashboard');
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 85);

    if (image == null) {
      return;
    }

    final savedPath = await _copyImageToAppStorage(image);
    if (!mounted) {
      return;
    }

    setState(() => _photoPath = savedPath);
  }

  Future<String> _copyImageToAppStorage(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final photosDirectory = Directory('${directory.path}/meal_photos');

    if (!await photosDirectory.exists()) {
      await photosDirectory.create(recursive: true);
    }

    final extension = image.path.contains('.')
        ? image.path.substring(image.path.lastIndexOf('.'))
        : '.jpg';
    final fileName = 'meal_${DateTime.now().microsecondsSinceEpoch}$extension';
    final targetPath = '${photosDirectory.path}/$fileName';
    final copied = await File(image.path).copy(targetPath);
    return copied.path;
  }

  Future<void> _analyzeWithAi() async {
    final strings = stringsFor(ref);

    if (_photoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.aiAnalysisNeedsPhoto)),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final bytes = await File(_photoPath!).readAsBytes();
      final response = await Supabase.instance.client.functions.invoke(
        'meal-photo-analyze',
        body: {
          'imageBase64': base64Encode(bytes),
        },
      );

      final analysis =
          Map<String, dynamic>.from(response.data['analysis'] as Map);
      final name = analysis['name']?.toString();
      final estimatedCalories = analysis['estimatedCalories'] as num?;
      final estimatedProtein = analysis['estimatedProteinGrams'] as num?;
      final estimatedCarbs = analysis['estimatedCarbsGrams'] as num?;
      final estimatedFat = analysis['estimatedFatGrams'] as num?;
      final estimatedSugar = analysis['estimatedSugarGrams'] as num?;
      final estimatedFiber = analysis['estimatedFiberGrams'] as num?;
      final estimatedMealType = analysis['estimatedMealType']?.toString();
      final confidence = (analysis['confidence'] as num?)?.toDouble() ?? 0;

      if (name != null && name.trim().isNotEmpty) {
        _nameController.text = name.trim();
      }
      if (estimatedCalories != null) {
        _caloriesController.text = estimatedCalories.round().toString();
      }
      if (estimatedProtein != null) {
        _proteinController.text = estimatedProtein.round().toString();
      }
      if (estimatedCarbs != null) {
        _carbsController.text = estimatedCarbs.round().toString();
      }
      if (estimatedFat != null) {
        _fatController.text = estimatedFat.round().toString();
      }
      if (estimatedSugar != null) {
        _sugarController.text = estimatedSugar.round().toString();
      }
      if (estimatedFiber != null) {
        _fiberController.text = estimatedFiber.round().toString();
      }
      if (estimatedMealType != null &&
          ['breakfast', 'lunch', 'dinner', 'snack']
              .contains(estimatedMealType)) {
        setState(() => _mealType = estimatedMealType);
      }
      setState(() => _confidence = confidence);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${strings.aiAnalysisSuccess} ${strings.aiConfidenceLabel(confidence)}'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }
}
