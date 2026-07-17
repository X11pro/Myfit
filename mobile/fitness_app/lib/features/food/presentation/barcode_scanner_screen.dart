import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/app_language.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key, required this.strings});

  final AppStrings strings;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  bool _handled = false;
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.itf14,
        BarcodeFormat.qrCode,
      ],
      detectionSpeed: DetectionSpeed.normal,
      autoZoom: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission || _handled) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _controller.stop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.strings.barcodeScannerTitle)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    error.errorDetails?.message ?? error.errorCode.name,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            onDetect: (capture) {
              if (_handled) {
                return;
              }

              final code = capture.barcodes
                  .map((barcode) => barcode.rawValue?.trim())
                  .whereType<String>()
                  .firstWhere(
                    (value) => value.isNotEmpty,
                    orElse: () => '',
                  );
              if (code.isEmpty) {
                return;
              }

              _handled = true;
              Navigator.of(context).pop(code);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.strings.barcodeScannerHint,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
