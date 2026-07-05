import 'dart:io';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../shared/app_language.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../application/barcode_lookup_service.dart';
import 'barcode_scanner_screen.dart';

class SharedFoodCatalogScreen extends ConsumerStatefulWidget {
  const SharedFoodCatalogScreen({super.key});

  @override
  ConsumerState<SharedFoodCatalogScreen> createState() =>
      _SharedFoodCatalogScreenState();
}

class _SharedFoodCatalogScreenState
    extends ConsumerState<SharedFoodCatalogScreen> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _sugarController = TextEditingController();
  final _fiberController = TextEditingController();
  final _labelTextController = TextEditingController();

  bool _isBusy = false;
  bool _isLookingUpBarcode = false;
  double? _qualityScore;
  String? _qualityReason;
  String? _imageBase64;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _sugarController.dispose();
    _fiberController.dispose();
    _labelTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(ref);

    return Scaffold(
      appBar: AppTopBar(title: strings.addSharedFoodTitle, strings: strings),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            strings.addSharedFoodSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed:
                    _isBusy ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(strings.takePhotoButton),
              ),
              FilledButton.tonalIcon(
                onPressed:
                    _isBusy ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(strings.pickPhotoButton),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelTextController,
            maxLines: 6,
            decoration: InputDecoration(labelText: strings.labelTextLabel),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isBusy ? null : _parseWithAiOrOcr,
              child: Text(strings.parseWithAiButton),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: strings.foodNameLabel),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _brandController,
            decoration: InputDecoration(labelText: strings.brandLabel),
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
                onPressed: _isBusyForBarcode || !_supportsBarcodeScan
                    ? null
                    : _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner_outlined),
                label: Text(strings.scanBarcodeButton),
              ),
              OutlinedButton.icon(
                onPressed: _isBusyForBarcode ? null : _lookupBarcode,
                icon: const Icon(Icons.search_outlined),
                label: Text(
                  _isLookingUpBarcode
                      ? strings.barcodeLookupInProgress
                      : strings.lookupBarcodeButton,
                ),
              ),
            ],
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
          if (_qualityScore != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.qualityScoreLabel,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      strings.qualityScoreValue(_qualityScore!),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if ((_qualityReason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(strings.qualityReasonLabel),
                      const SizedBox(height: 4),
                      Text(_qualityReason!),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isBusy ? null : _saveSharedFood,
              child: Text(strings.saveSharedFoodButton),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 85);
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    setState(() {
      _imageBase64 = base64Encode(bytes);
    });
  }

  Future<void> _parseWithAiOrOcr() async {
    final strings = stringsFor(ref);
    if (!AppEnv.hasSupabaseConfig) {
      _showMessage(strings.missingSupabaseConfigMessage);
      return;
    }

    if (_labelTextController.text.trim().isEmpty && _imageBase64 == null) {
      _showMessage(strings.sharedFoodInvalidMessage);
      return;
    }

    setState(() => _isBusy = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'food-catalog-upsert',
        body: {
          'mode': 'extract',
          'barcode': _barcodeController.text.trim(),
          'ocrText': _labelTextController.text.trim(),
          'imageBase64': _imageBase64,
        },
      );

      final payload = _responseMap(response.data);
      _throwIfFunctionError(payload);
      final food =
          _nestedMap(payload, 'food', strings.sharedFoodInvalidResponse);
      _nameController.text = food['name']?.toString() ?? '';
      _brandController.text = food['brand']?.toString() ?? '';
      _caloriesController.text = _numberText(food['caloriesPer100g']);
      _proteinController.text = _numberText(food['proteinPer100g']);
      _carbsController.text = _numberText(food['carbsPer100g']);
      _fatController.text = _numberText(food['fatPer100g']);
      _sugarController.text = _numberText(food['sugarPer100g']);
      _fiberController.text = _numberText(food['fiberPer100g']);

      setState(() {
        _qualityScore = (food['nutritionQualityScore'] as num?)?.toDouble();
        _qualityReason = food['nutritionQualityReason']?.toString();
      });
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  bool get _supportsBarcodeScan =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get _isBusyForBarcode => _isBusy || _isLookingUpBarcode;

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
      _showMessage(strings.missingSupabaseConfigMessage);
      return;
    }

    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      _showMessage(strings.barcodeLookupNeedsCode);
      return;
    }

    setState(() => _isLookingUpBarcode = true);
    try {
      final result =
          await ref.read(barcodeLookupServiceProvider).lookup(barcode);

      if (result == null) {
        _showMessage(strings.barcodeLookupNoMatch);
        return;
      }

      _nameController.text = result.name;
      _brandController.text = result.brand ?? '';
      _caloriesController.text = _numberText(result.caloriesPer100g);
      _proteinController.text = _numberText(result.proteinPer100g);
      _carbsController.text = _numberText(result.carbsPer100g);
      _fatController.text = _numberText(result.fatPer100g);
      _sugarController.text = _numberText(result.sugarPer100g);
      _fiberController.text = _numberText(result.fiberPer100g);

      setState(() {
        _qualityScore = null;
        _qualityReason = null;
      });

      _showMessage(strings.barcodeLookupSuccess);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLookingUpBarcode = false);
      }
    }
  }

  Future<void> _saveSharedFood() async {
    final strings = stringsFor(ref);
    if (!AppEnv.hasSupabaseConfig) {
      _showMessage(strings.missingSupabaseConfigMessage);
      return;
    }

    if (_nameController.text.trim().isEmpty &&
        _labelTextController.text.trim().isEmpty &&
        _imageBase64 == null) {
      _showMessage(strings.sharedFoodInvalidMessage);
      return;
    }

    setState(() => _isBusy = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'food-catalog-upsert',
        body: {
          'mode': 'upsert',
          'barcode': _barcodeController.text.trim(),
          'ocrText': _labelTextController.text.trim(),
          'imageBase64': _imageBase64,
          'name': _nameController.text.trim(),
          'brand': _brandController.text.trim(),
          'caloriesPer100g': _tryNumber(_caloriesController.text),
          'proteinPer100g': _tryNumber(_proteinController.text),
          'carbsPer100g': _tryNumber(_carbsController.text),
          'fatPer100g': _tryNumber(_fatController.text),
          'sugarPer100g': _tryNumber(_sugarController.text),
          'fiberPer100g': _tryNumber(_fiberController.text),
        },
      );

      final payload = _responseMap(response.data);
      _throwIfFunctionError(payload);
      final food =
          _nestedMap(payload, 'food', strings.sharedFoodInvalidResponse);
      setState(() {
        _qualityScore = (food['nutrition_quality_score'] as num?)?.toDouble();
        _qualityReason = food['nutrition_quality_reason']?.toString();
      });

      if (!mounted) {
        return;
      }

      _showMessage(strings.sharedFoodSavedMessage);
      context.go('/dashboard');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  double? _tryNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  String _numberText(Object? value) {
    if (value is num) {
      return value.toString();
    }

    return '';
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

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
