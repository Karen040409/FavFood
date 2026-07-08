import 'dart:convert';

import 'package:flutter/material.dart';

/// Displays a recipe image from:
///   - A local asset path  (e.g. "images/sushi.jpg")
///   - A network URL       (e.g. "https://firebasestorage.googleapis.com/...")
///   - An inline data URL  (Firestore fallback when Storage is unavailable)
class RecipeImage extends StatelessWidget {
  const RecipeImage({
    super.key,
    required this.imageAsset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String imageAsset;
  final BoxFit fit;
  final double? width;
  final double? height;

  bool get _isDataUrl => imageAsset.startsWith('data:');

  bool get _isNetwork =>
      imageAsset.startsWith('http://') || imageAsset.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imageAsset.isEmpty) return _placeholder(colorScheme);

    if (_isDataUrl) {
      final commaIndex = imageAsset.indexOf(',');
      if (commaIndex == -1) return _placeholder(colorScheme);

      try {
        final bytes = base64Decode(imageAsset.substring(commaIndex + 1));
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (ctx, e, stack) => _placeholder(colorScheme),
        );
      } catch (_) {
        return _placeholder(colorScheme);
      }
    }

    if (_isNetwork) {
      return Image.network(
        imageAsset,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return _loading(colorScheme);
        },
        errorBuilder: (ctx, e, stack) => _placeholder(colorScheme),
      );
    }

    return Image.asset(
      imageAsset,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (ctx, e, stack) => _placeholder(colorScheme),
    );
  }

  Widget _loading(ColorScheme cs) => Container(
        width: width,
        height: height,
        color: cs.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _placeholder(ColorScheme cs) => Container(
        width: width,
        height: height,
        color: cs.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.restaurant_rounded,
            size: (width != null && width! < 60) ? 24 : 48,
            color: cs.outlineVariant,
          ),
        ),
      );
}
