import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'storage_service.dart';

class UserProfileService {
  UserProfileService._();
  static final UserProfileService instance = UserProfileService._();

  static const usersCollection = 'users';
  static const _maxFirestorePhotoBytes = 700000;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return FirebaseFirestore.instance.collection(usersCollection).doc(uid);
  }

  Stream<String?> photoUrlStream(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      final url = data?['photoUrl'];
      return url is String && url.isNotEmpty ? url : null;
    });
  }

  Future<String> uploadAndSaveProfilePhoto(XFile imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to upload a profile photo.');
    }

    late final String downloadUrl;

    try {
      downloadUrl = await StorageService.instance.uploadProfilePhoto(imageFile);
    } catch (storageError) {
      if (!_shouldUseFirestoreFallback(storageError)) {
        rethrow;
      }
      downloadUrl = await _savePhotoDataUrlToFirestore(imageFile, user);
    }

    try {
      await user.updatePhotoURL(downloadUrl);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        rethrow;
      }
    }

    if (!downloadUrl.startsWith('data:')) {
      await _userDoc(user.uid).set(
        {
          'photoUrl': downloadUrl,
          'photoUpdatedAt': FieldValue.serverTimestamp(),
          'email': user.email,
          'displayName': user.displayName,
        },
        SetOptions(merge: true),
      );
    }

    await user.reload();
    return downloadUrl;
  }

  bool _shouldUseFirestoreFallback(Object error) {
    if (error is TimeoutException) return true;

    final message = error.toString().toLowerCase();
    return message.contains('storage') ||
        message.contains('timed out') ||
        message.contains('permission-denied') ||
        message.contains('object-not-found') ||
        message.contains('bucket');
  }

  Future<String> _savePhotoDataUrlToFirestore(XFile imageFile, User user) async {
    final bytes = await imageFile.readAsBytes().timeout(const Duration(seconds: 15));

    if (bytes.length > _maxFirestorePhotoBytes) {
      throw StateError(
        'Photo is too large. Enable Firebase Storage in the console, or choose a smaller image.',
      );
    }

    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    await _userDoc(user.uid).set(
      {
        'photoUrl': dataUrl,
        'photoUpdatedAt': FieldValue.serverTimestamp(),
        'email': user.email,
        'displayName': user.displayName,
        'photoStorage': 'firestore',
      },
      SetOptions(merge: true),
    );

    return dataUrl;
  }
}
