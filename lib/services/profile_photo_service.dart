import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'recipe_image_picker.dart';
import 'user_profile_service.dart';

class ProfilePhotoService {
  ProfilePhotoService._();
  static final ProfilePhotoService instance = ProfilePhotoService._();

  Future<void> pickAndUpload(BuildContext context) async {
    final source = await _pickSource(context);
    if (source == null || !context.mounted) return;

    var loadingShown = false;

    try {
      final picked = await RecipeImagePicker.pickXFile(source: source);
      if (picked == null || !context.mounted) return;

      _showLoading(context);
      loadingShown = true;

      final savedUrl = await UserProfileService.instance.uploadAndSaveProfilePhoto(picked);

      if (context.mounted) {
        final usedFallback = savedUrl.startsWith('data:');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              usedFallback
                  ? 'Profile photo saved. Enable Firebase Storage for cloud file uploads.'
                  : 'Profile photo updated',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e))),
        );
      }
    } finally {
      if (loadingShown && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('too large')) {
      return message.replaceFirst('StateError: ', '');
    }
    if (message.contains('unauthorized') || message.contains('permission-denied')) {
      return 'Upload blocked. Enable Firebase Storage, then run: firebase deploy --only storage --project favfood-map';
    }
    if (message.contains('timed out') || message.contains('Storage may not be enabled')) {
      return 'Upload timed out. Open Firebase Console → Storage → Get started, then try again.';
    }
    if (message.contains('requires-recent-login')) {
      return 'Please sign out and sign in again, then retry uploading your photo.';
    }
    return 'Could not update photo: $error';
  }

  void _showLoading(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading photo…'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<ImageSource?> _pickSource(BuildContext context) async {
    if (kIsWeb) {
      return ImageSource.gallery;
    }

    final canUseCamera = RecipeImagePicker.isCameraSupported;

    return showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            if (canUseCamera)
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
          ],
        ),
      ),
    );
  }
}
