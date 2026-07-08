import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Handles uploading images to Firebase Storage.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _uploadTimeout = Duration(seconds: 25);
  static const _maxInlinePhotoBytes = 700000;

  final _storage = FirebaseStorage.instance;

  Future<String> uploadRecipeImage(XFile imageFile) async {
    try {
      return await _uploadRecipeToStorage(imageFile);
    } catch (error) {
      if (!_shouldUseInlineFallback(error)) rethrow;
      return _toDataUrl(imageFile);
    }
  }

  Future<String> uploadProfilePhoto(XFile imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to upload a profile photo.');
    }

    final extension = _fileExtension(imageFile.name);
    final ref = _storage.ref().child('profile_photos/${user.uid}/avatar$extension');
    final metadata = SettableMetadata(contentType: _contentTypeForExtension(extension));

    try {
      await _putXFile(ref, imageFile, metadata);
      return ref.getDownloadURL().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw StateError(
        'Upload timed out. Firebase Storage may not be enabled yet.',
      );
    } on FirebaseException catch (e) {
      throw StateError('Storage upload failed (${e.code}): ${e.message}');
    }
  }

  Future<String> _uploadRecipeToStorage(XFile imageFile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final extension = _fileExtension(imageFile.name);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$uid$extension';
    final ref = _storage.ref().child('recipe_images/$fileName');
    final metadata = SettableMetadata(contentType: _contentTypeForExtension(extension));

    try {
      await _putXFile(ref, imageFile, metadata);
      return ref.getDownloadURL().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw StateError(
        'Upload timed out. Firebase Storage may not be enabled yet.',
      );
    } on FirebaseException catch (e) {
      throw StateError('Storage upload failed (${e.code}): ${e.message}');
    }
  }

  Future<void> _putXFile(
    Reference ref,
    XFile imageFile,
    SettableMetadata metadata,
  ) async {
    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes().timeout(_uploadTimeout);
      await ref.putData(bytes, metadata).timeout(_uploadTimeout);
      return;
    }

    await ref.putFile(File(imageFile.path), metadata).timeout(_uploadTimeout);
  }

  Future<String> _toDataUrl(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes().timeout(const Duration(seconds: 15));
    if (bytes.length > _maxInlinePhotoBytes) {
      throw StateError(
        'Photo is too large. Enable Firebase Storage in the console, or choose a smaller image.',
      );
    }

    final extension = _fileExtension(imageFile.name);
    final mime = _contentTypeForExtension(extension);
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  bool _shouldUseInlineFallback(Object error) {
    if (error is TimeoutException) return true;

    final message = error.toString().toLowerCase();
    return message.contains('storage') ||
        message.contains('timed out') ||
        message.contains('permission-denied') ||
        message.contains('object-not-found') ||
        message.contains('bucket');
  }

  String _fileExtension(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) {
      return '.jpg';
    }

    final ext = name.substring(dotIndex).toLowerCase();
    const allowed = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};
    return allowed.contains(ext) ? (ext == '.jpeg' ? '.jpg' : ext) : '.jpg';
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }
}
