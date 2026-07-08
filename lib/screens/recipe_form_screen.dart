import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/ingredient_model.dart';
import '../models/recipe_model.dart';
import '../services/recipe_image_picker.dart';
import '../services/storage_service.dart';
import '../viewmodels/recipe_list_view_model.dart';
import '../widgets/recipe_image.dart';

class _IngredientEntry {
  _IngredientEntry({String? name, double? qty, String? unit})
      : nameCtrl = TextEditingController(text: name ?? ''),
        qtyCtrl = TextEditingController(text: qty != null ? '$qty' : ''),
        unitCtrl = TextEditingController(text: unit ?? '');

  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
  }

  IngredientModel toIngredient() => IngredientModel(
        name: nameCtrl.text.trim(),
        baseQuantity: double.tryParse(qtyCtrl.text.trim()) ?? 0,
        unit: unitCtrl.text.trim(),
      );
}

class RecipeFormScreen extends StatefulWidget {
  const RecipeFormScreen({super.key, this.existingRecipe});

  final RecipeModel? existingRecipe;

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _prepCtrl;
  late final TextEditingController _cookCtrl;
  late final TextEditingController _feedsCtrl;

  bool _isVegetarian = false;
  bool _isSaving = false;

  /// Locally picked image (before upload)
  XFile? _pickedImageFile;
  Uint8List? _pickedImageBytes;

  /// Already-saved image URL (from existing recipe or after upload)
  String _imageUrl = '';

  final List<_IngredientEntry> _ingredients = [];

  bool get _isEditing => widget.existingRecipe != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRecipe;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _prepCtrl = TextEditingController(text: r?.prepTime ?? '');
    _cookCtrl = TextEditingController(text: r?.cookTime ?? '');
    _feedsCtrl = TextEditingController(text: r?.feeds ?? '');
    _isVegetarian = r?.isVegetarian ?? false;
    _imageUrl = r?.imageAsset ?? '';

    if (r != null && r.ingredients.isNotEmpty) {
      for (final ing in r.ingredients) {
        _ingredients.add(_IngredientEntry(
          name: ing.name,
          qty: ing.baseQuantity,
          unit: ing.unit,
        ));
      }
    } else {
      _ingredients.add(_IngredientEntry());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _prepCtrl.dispose();
    _cookCtrl.dispose();
    _feedsCtrl.dispose();
    for (final e in _ingredients) {
      e.dispose();
    }
    super.dispose();
  }

  // ── Image Picking ─────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await RecipeImagePicker.pickXFile(source: source);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _pickedImageFile = picked;
        _pickedImageBytes = bytes;
        _imageUrl = '';
      });
    } on UnsupportedError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Not supported on this device.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    if (kIsWeb) {
      _pickImage(ImageSource.gallery);
      return;
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Add Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (RecipeImagePicker.isCameraSupported)
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.camera_alt_rounded),
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.photo_library_rounded),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_pickedImageFile != null || _imageUrl.isNotEmpty)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedImageFile = null;
                      _pickedImageBytes = null;
                      _imageUrl = '';
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient.')),
      );
      return;
    }

    final ingredientObjects =
        _ingredients.map((e) => e.toIngredient()).toList();

    for (int i = 0; i < ingredientObjects.length; i++) {
      final ing = ingredientObjects[i];
      if (ing.name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ingredient ${i + 1} name cannot be empty.')),
        );
        return;
      }
      if (ing.baseQuantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Ingredient ${i + 1} quantity must be greater than 0.')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final vm = context.read<RecipeListViewModel>();

    try {
      // Upload image if a new one was picked
      String finalImageUrl = _imageUrl;
      if (_pickedImageFile != null) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Uploading photo…'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );

        try {
          finalImageUrl =
              await StorageService.instance.uploadRecipeImage(_pickedImageFile!);
        } finally {
          if (mounted) messenger.hideCurrentSnackBar();
        }

        if (finalImageUrl.startsWith('data:') && mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Photo saved with recipe. Enable Firebase Storage for cloud uploads.',
              ),
            ),
          );
        }
      }

      final recipe = RecipeModel(
        id: widget.existingRecipe?.id ?? '',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageAsset: finalImageUrl,
        isVegetarian: _isVegetarian,
        prepTime: _prepCtrl.text.trim(),
        cookTime: _cookCtrl.text.trim(),
        feeds: _feedsCtrl.text.trim(),
        ingredients: ingredientObjects,
        createdBy: widget.existingRecipe?.createdBy ?? '',
        favoritedBy: widget.existingRecipe?.favoritedBy ?? [],
      );

      if (_isEditing) {
        await vm.updateRecipe(recipe);
      } else {
        await vm.addRecipe(recipe);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlySaveError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _friendlySaveError(Object error) {
    final message = error.toString();
    if (message.contains('too large')) {
      return message.replaceFirst('StateError: ', '');
    }
    if (message.contains('timed out') || message.contains('Storage may not be enabled')) {
      return 'Photo upload timed out. Enable Firebase Storage in the console, then try again.';
    }
    return 'Error saving recipe: $error';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Recipe' : 'New Recipe'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Photo Picker ────────────────────────────────────────────────
            _buildPhotoPicker(colorScheme),
            const SizedBox(height: 24),

            _SectionHeader(title: 'Basic Info', icon: Icons.info_outline_rounded),
            const SizedBox(height: 12),

            // Name
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Recipe Name *',
                prefixIcon: Icon(Icons.restaurant_menu_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Recipe name is required.';
                }
                if (v.trim().length < 3) return 'Name must be at least 3 characters.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.description_rounded),
                ),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Description is required.';
                if (v.trim().length < 10) {
                  return 'Description must be at least 10 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            _SectionHeader(
                title: 'Time & Servings', icon: Icons.timer_rounded),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Prep Time *',
                      hintText: 'e.g. 20 min',
                      prefixIcon: Icon(Icons.kitchen_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cookCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cook Time *',
                      hintText: 'e.g. 1 hr',
                      prefixIcon: Icon(Icons.timer_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _feedsCtrl,
              decoration: const InputDecoration(
                labelText: 'Feeds / Servings *',
                hintText: 'e.g. 4 or 2-4',
                prefixIcon: Icon(Icons.people_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Vegetarian switch
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: SwitchListTile(
                title: const Text('Vegetarian'),
                subtitle: const Text('No meat or seafood'),
                secondary: const Icon(Icons.eco_rounded),
                value: _isVegetarian,
                onChanged: (v) => setState(() => _isVegetarian = v),
              ),
            ),
            const SizedBox(height: 24),

            // Ingredients
            Row(
              children: [
                _SectionHeader(
                    title: 'Ingredients', icon: Icons.list_alt_rounded),
                const Spacer(),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _ingredients.add(_IngredientEntry())),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_ingredients.isEmpty)
              Center(
                child: Text(
                  'No ingredients added yet.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),

            ...List.generate(_ingredients.length, (i) {
              final entry = _ingredients[i];
              return _IngredientRow(
                index: i,
                entry: entry,
                onRemove: () => setState(() {
                  entry.dispose();
                  _ingredients.removeAt(i);
                }),
              );
            }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(ColorScheme colorScheme) {
    final hasImage =
        _pickedImageBytes != null || _pickedImageFile != null || _imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage
                ? Colors.transparent
                : colorScheme.outlineVariant,
            width: 2,
          ),
          color: hasImage ? null : colorScheme.surfaceContainerHighest,
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage ? _buildImagePreview(colorScheme) : _buildAddPhotoHint(colorScheme),
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        if (_pickedImageBytes != null)
          Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
        else
          RecipeImage(imageAsset: _imageUrl, fit: BoxFit.cover),

        // Edit overlay
        Positioned(
          bottom: 10,
          right: 10,
          child: Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _showImageSourceSheet,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Change',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoHint(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded,
            size: 52, color: colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          'Add Photo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          RecipeImagePicker.isCameraSupported
              ? 'Tap to choose from gallery or take a photo'
              : 'Tap to choose a photo from your files',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Ingredient Row ────────────────────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.index,
    required this.entry,
    required this.onRemove,
  });

  final int index;
  final _IngredientEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: entry.nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Ingredient ${index + 1}',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name required' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Qty',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return '> 0';
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.unitCtrl,
              decoration: const InputDecoration(
                labelText: 'Unit',
                hintText: 'g, ml…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded,
                color: Colors.red),
            tooltip: 'Remove',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
