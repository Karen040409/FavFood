import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe_model.dart';
import '../viewmodels/recipe_list_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/recipe_image.dart';
import 'recipe_list_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecipeListViewModel>();
    final favorites = vm.favoriteRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favourites'),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.transparent,
      body: favorites.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No favourites yet.',
              subtitle: 'Tap the heart icon on a recipe to save it here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final recipe = favorites[index];
                return _FavouriteCard(recipe: vm.recipeById(recipe.id) ?? recipe);
              },
            ),
    );
  }
}

class _FavouriteCard extends StatelessWidget {
  const _FavouriteCard({required this.recipe});

  final RecipeModel recipe;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<RecipeListViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => openRecipeDetail(context, recipe),
        child: Row(
          children: [
            // Image
            SizedBox(
              width: 90,
              height: 90,
              child: RecipeImage(
                imageAsset: recipe.imageAsset,
                fit: BoxFit.cover,
                width: 90,
                height: 90,
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      recipe.isVegetarian
                          ? 'Vegetarian'
                          : 'Contains meat/seafood',
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${recipe.prepTime} prep · ${recipe.cookTime} cook · feeds ${recipe.feeds}',
                      style: TextStyle(
                          fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),

            // Unfavorite button
            IconButton(
              icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
              tooltip: 'Remove from favourites',
              onPressed: () async {
                try {
                  await vm.toggleFavorite(recipe);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not update favorite: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
