import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe_model.dart';
import '../viewmodels/recipe_detail_view_model.dart';
import '../viewmodels/recipe_list_view_model.dart';
import '../widgets/recipe_image.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecipeDetailViewModel>();
    final listVm = context.read<RecipeListViewModel>();
    final recipe = viewModel.recipe;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible AppBar with Hero image ─────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'recipe_image_${recipe.id}',
                child: _buildHeroImage(recipe, colorScheme),
              ),
            ),
            actions: [
              // Favorite button
              Consumer<RecipeListViewModel>(
                builder: (context, vm, _) {
                  final liveRecipe = vm.recipeById(recipe.id) ?? recipe;
                  final isFav = liveRecipe.isFavoritedBy(vm.currentUid);
                  return IconButton(
                    tooltip: isFav ? 'Remove favorite' : 'Add favorite',
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(isFav),
                        color: isFav ? Colors.redAccent : null,
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await listVm.toggleFavorite(liveRecipe);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not update favorite: $e')),
                          );
                        }
                      }
                    },
                  );
                },
              ),

              // Edit (only owner)
              if (viewModel.isOwner)
                IconButton(
                  tooltip: 'Edit recipe',
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () {
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RecipeFormScreen(existingRecipe: recipe),
                      ),
                    );
                    // Firestore stream auto-updates; no manual refresh needed
                  },
                ),

              // Delete (only owner)
              if (viewModel.isOwner)
                IconButton(
                  tooltip: 'Delete recipe',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _confirmDelete(context, recipe, listVm),
                ),
            ],
          ),

          // ── Content ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + veg badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (recipe.isVegetarian)
                        Container(
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.eco_rounded,
                                  size: 14, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Veg',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    recipe.description,
                    style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Time / Servings Info Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _InfoBlock(
                            icon: Icons.kitchen_rounded,
                            label: 'PREP',
                            value: recipe.prepTime,
                            color: Colors.orange),
                        _Divider(),
                        _InfoBlock(
                            icon: Icons.timer_rounded,
                            label: 'COOK',
                            value: recipe.cookTime,
                            color: Colors.blue),
                        _Divider(),
                        _InfoBlock(
                            icon: Icons.people_rounded,
                            label: 'FEEDS',
                            value: recipe.feeds,
                            color: Colors.purple),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Ingredients header
                  Text(
                    'Ingredients',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),

                  // Servings selector
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded),
                              color: colorScheme.onPrimaryContainer,
                              onPressed: viewModel.decrementServings,
                              iconSize: 20,
                            ),
                            ListenableBuilder(
                              listenable: viewModel,
                              builder: (context, _) => Text(
                                '${viewModel.servingSize} serving${viewModel.servingSize > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded),
                              color: colorScheme.onPrimaryContainer,
                              onPressed: viewModel.incrementServings,
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Ingredient list
                  ListenableBuilder(
                    listenable: viewModel,
                    builder: (context, _) => Column(
                      children: viewModel.scaledIngredientLabels
                          .map((label) => _IngredientTile(label: label))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(RecipeModel recipe, ColorScheme cs) {
    return RecipeImage(
      imageAsset: recipe.imageAsset,
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RecipeModel recipe,
    RecipeListViewModel listVm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recipe?'),
        content:
            Text('Are you sure you want to delete "${recipe.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await listVm.deleteRecipe(recipe.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ── Info Block ────────────────────────────────────────────────────────────────

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 40, width: 1, color: Colors.grey.shade300);
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
