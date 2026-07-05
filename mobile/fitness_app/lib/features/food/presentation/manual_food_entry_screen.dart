import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../shared/app_language.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../application/barcode_lookup_service.dart';
import '../domain/barcode_food_lookup_result.dart';
import '../application/manual_food_entries_controller.dart';
import '../domain/manual_food_entry.dart';
import 'barcode_scanner_screen.dart';

class ManualFoodEntryScreen extends ConsumerStatefulWidget {
  const ManualFoodEntryScreen({super.key, this.entry});

  final ManualFoodEntry? entry;

  @override
  ConsumerState<ManualFoodEntryScreen> createState() =>
      _ManualFoodEntryScreenState();
}

class _ManualFoodEntryScreenState extends ConsumerState<ManualFoodEntryScreen> {
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _sugarController = TextEditingController();
  final _fiberController = TextEditingController();
  String _mealType = 'breakfast';
  String? _photoPath;
  bool _isAnalyzing = false;
  bool _isLookingUpBarcode = false;
  double? _confidence;
  BarcodeFoodLookupResult? _barcodeResult;

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
    _barcodeController.dispose();
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
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/food/gallery'),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(strings.foodGalleryTitle),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: strings.foodNameLabel),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _barcodeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: strings.barcodeLabel),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: _isBusyForExternalActions || !_supportsBarcodeScan
                    ? null
                    : _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner_outlined),
                label: Text(strings.scanBarcodeButton),
              ),
              OutlinedButton.icon(
                onPressed: _isBusyForExternalActions ? null : _lookupBarcode,
                icon: const Icon(Icons.search_outlined),
                label: Text(
                  _isLookingUpBarcode
                      ? strings.barcodeLookupInProgress
                      : strings.lookupBarcodeButton,
                ),
              ),
            ],
          ),
          if (_barcodeResult != null) ...[
            const SizedBox(height: 16),
            _buildBarcodeResultCard(strings),
          ],
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
              child: _buildPhotoPreview(strings),
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
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      return _toDataUrl(bytes, image.mimeType);
    }

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

    if (!AppEnv.hasSupabaseConfig) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.missingSupabaseConfigMessage)),
      );
      return;
    }

    if (_photoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.aiAnalysisNeedsPhoto)),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final bytes = await _loadPhotoBytes(_photoPath!);
      final response = await Supabase.instance.client.functions.invoke(
        'meal-photo-analyze',
        body: {
          'imageBase64': base64Encode(bytes),
        },
      );

      final payload = _responseMap(response.data);
      _throwIfFunctionError(payload);
      final analysis =
          _nestedMap(payload, 'analysis', strings.aiAnalysisInvalidResponse);
      final name = analysis['name']?.toString();
      final estimatedCalories = analysis['estimatedCalories'] as num?;
      final estimatedProtein = analysis['estimatedProteinGrams'] as num?;
      final estimatedCarbs = analysis['estimatedCarbsGrams'] as num?;
      final estimatedFat = analysis['estimatedFatGrams'] as num?;
      final estimatedSugar = analysis['estimatedSugarGrams'] as num?;
      final estimatedFiber = analysis['estimatedFiberGrams'] as num?;
      final estimatedMealType = analysis['estimatedMealType']?.toString();
      final confidence = ((analysis['confidence'] as num?)?.toDouble() ?? 0)
          .clamp(0, 1)
          .toDouble();

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

  bool get _supportsBarcodeScan =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get _isBusyForExternalActions => _isAnalyzing || _isLookingUpBarcode;

  Future<void> _scanBarcode() async {
    final strings = stringsFor(ref);
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(strings: strings),
      ),
    );

    if (!mounted || barcode == null || barcode.trim().isEmpty) {
      return;
    }

    _barcodeController.text = barcode.trim();
    await _lookupBarcode();
  }

  Future<void> _lookupBarcode() async {
    final strings = stringsFor(ref);

    if (!AppEnv.hasSupabaseConfig) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.missingSupabaseConfigMessage)),
      );
      return;
    }

    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.barcodeLookupNeedsCode)),
      );
      return;
    }

    setState(() => _isLookingUpBarcode = true);
    try {
      final result =
          await ref.read(barcodeLookupServiceProvider).lookup(barcode);

      if (result == null) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.barcodeLookupNoMatch)),
        );
        return;
      }

      _nameController.text = result.name;
      if (result.caloriesPer100g != null) {
        _caloriesController.text = result.caloriesPer100g!.round().toString();
      }
      if (result.proteinPer100g != null) {
        _proteinController.text = result.proteinPer100g!.round().toString();
      }
      if (result.carbsPer100g != null) {
        _carbsController.text = result.carbsPer100g!.round().toString();
      }
      if (result.fatPer100g != null) {
        _fatController.text = result.fatPer100g!.round().toString();
      }
      if (result.sugarPer100g != null) {
        _sugarController.text = result.sugarPer100g!.round().toString();
      }
      if (result.fiberPer100g != null) {
        _fiberController.text = result.fiberPer100g!.round().toString();
      }

      setState(() => _confidence = result.confidence);
      setState(() => _barcodeResult = result);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.barcodeLookupSuccess)),
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
        setState(() => _isLookingUpBarcode = false);
      }
    }
  }

  Widget _buildBarcodeResultCard(AppStrings strings) {
    final result = _barcodeResult!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.barcodeResultTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(strings.barcodeResultSubtitle),
            const SizedBox(height: 12),
            Text(
              result.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if ((result.brand ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(result.brand!),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(strings.barcodeSourceValue(result.source)),
                ),
                Chip(
                  label: Text(result.cached
                      ? strings.barcodeCachedLabel
                      : strings.barcodeFreshLookupLabel),
                ),
                if ((result.sourceId ?? '').isNotEmpty)
                  Chip(label: Text(result.sourceId!)),
                if (result.confidence != null)
                  Chip(
                    label: Text(strings.aiConfidenceLabel(result.confidence!)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(AppStrings strings) {
    final photoPath = _photoPath;
    if (photoPath == null) {
      return const SizedBox.shrink();
    }

    ImageProvider imageProvider;
    if (_isDataUrl(photoPath)) {
      imageProvider = MemoryImage(_dataUrlBytes(photoPath));
    } else {
      imageProvider = FileImage(File(photoPath));
    }

    return Image(
      image: imageProvider,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 180,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(strings.noMealsYet),
        );
      },
    );
  }

  Future<Uint8List> _loadPhotoBytes(String photoPath) async {
    if (_isDataUrl(photoPath)) {
      return _dataUrlBytes(photoPath);
    }

    return File(photoPath).readAsBytes();
  }

  bool _isDataUrl(String value) => value.startsWith('data:');

  Uint8List _dataUrlBytes(String dataUrl) {
    final commaIndex = dataUrl.indexOf(',');
    if (commaIndex < 0 || commaIndex == dataUrl.length - 1) {
      throw StateError('Invalid photo data.');
    }

    return base64Decode(dataUrl.substring(commaIndex + 1));
  }

  String _toDataUrl(Uint8List bytes, String? mimeType) {
    final resolvedMimeType =
        mimeType?.trim().isNotEmpty == true ? mimeType! : 'image/jpeg';
    return 'data:$resolvedMimeType;base64,${base64Encode(bytes)}';
  }

  Map<String, dynamic> _responseMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw StateError('Invalid function response.');
  }

  Map<String, dynamic> _nestedMap(
    Map<String, dynamic> payload,
    String key,
    String fallbackMessage,
  ) {
    final value = payload[key];
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw StateError(fallbackMessage);
  }

  void _throwIfFunctionError(Map<String, dynamic> payload) {
    final error = payload['error'];
    if (error != null) {
      throw StateError(error.toString());
    }
  }
}
