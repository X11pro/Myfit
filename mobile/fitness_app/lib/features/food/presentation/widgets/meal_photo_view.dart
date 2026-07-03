import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class MealPhotoView extends StatelessWidget {
  const MealPhotoView({
    super.key,
    required this.photoPath,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.placeholder,
    this.fit = BoxFit.cover,
  });

  final String photoPath;
  final double width;
  final double height;
  final double borderRadius;
  final Widget? placeholder;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image(
        image: _imageProvider(photoPath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_outlined),
              );
        },
      ),
    );
  }

  ImageProvider _imageProvider(String value) {
    if (value.startsWith('data:')) {
      return MemoryImage(_dataUrlBytes(value));
    }

    return FileImage(File(value));
  }

  Uint8List _dataUrlBytes(String dataUrl) {
    final commaIndex = dataUrl.indexOf(',');
    if (commaIndex < 0 || commaIndex == dataUrl.length - 1) {
      throw StateError('Invalid photo data.');
    }

    return base64Decode(dataUrl.substring(commaIndex + 1));
  }
}
