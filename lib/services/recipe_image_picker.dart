import 'dart:io' show File;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Picks a recipe photo using the correct implementation per platform.
class RecipeImagePicker {
  RecipeImagePicker._();

  static const _imageGroup = XTypeGroup(
    label: 'Images',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
  );

  static bool get isCameraSupported => !_isDesktop;

  static bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static Future<XFile?> pickXFile({required ImageSource source}) async {
    if (_isDesktop) {
      if (source == ImageSource.camera) {
        throw UnsupportedError('Camera is not available on desktop.');
      }
      return openFile(acceptedTypeGroups: [_imageGroup]);
    }

    return ImagePicker().pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1024,
    );
  }

  static Future<File?> pick({required ImageSource source}) async {
    final xFile = await pickXFile(source: source);
    if (xFile == null) return null;
    if (kIsWeb) return null;
    return File(xFile.path);
  }
}
