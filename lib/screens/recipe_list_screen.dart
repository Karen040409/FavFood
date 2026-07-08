import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe_model.dart';
import '../viewmodels/recipe_detail_view_model.dart';
import '../viewmodels/recipe_list_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/recipe_image.dart';
import '../widgets/section_header.dart';
import 'recipe_detail_screen.dart';
import 'recipe_form_screen.dart';

void openRecipeDetail(BuildContext context, RecipeModel recipe) {
  final listViewModel = context.read<RecipeListViewModel>();

  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => ChangeNotifierProvider(
        create: (_) => RecipeDetailViewModel(
          recipe,
          onFavoriteChanged: listViewModel.notifyRecipesChanged,
        ),
        child: const RecipeDetailScreen(),
      ),
    ),
  );
}

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RecipeListView();
  }
}

class _RecipeListView extends StatefulWidget {
  const _RecipeListView();

  @override
  State<_RecipeListView> createState() => _RecipeListViewState();
}

class _RecipeListViewState extends State<_RecipeListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecipeListViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ── Search Bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search recipes…',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      vm.setSearchQuery('');
                    },
                  ),
              ],
              onChanged: vm.setSearchQuery,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // ── Category Filter Chips ────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _CategoryChip(
                  label: 'All',
                  icon: Icons.restaurant_rounded,
                  selected: vm.categoryFilter == CategoryFilter.all,
                  onSelected: () => vm.setCategoryFilter(CategoryFilter.all),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Vegetarian',
                  icon: Icons.eco_rounded,
                  selected: vm.categoryFilter == CategoryFilter.vegetarian,
                  onSelected: () =>
                      vm.setCategoryFilter(CategoryFilter.vegetarian),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Non-Vegetarian',
                  icon: Icons.set_meal_rounded,
                  selected: vm.categoryFilter == CategoryFilter.nonVegetarian,
                  onSelected: () =>
                      vm.setCategoryFilter(CategoryFilter.nonVegetarian),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(child: _buildBody(context, vm)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_recipe_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => const RecipeFormScreen(),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Recipe'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RecipeListViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load recipes from Firestore.',
        subtitle: vm.errorMessage,
      );
    }

    final myRecipes = vm.displayedMyRecipes;
    final otherRecipes = vm.displayedOtherRecipes;

    if (myRecipes.isEmpty && otherRecipes.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No recipes found.',
        subtitle: 'Try a different search or add a new recipe.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (myRecipes.isNotEmpty) ...[
          SectionHeader(
            title: 'My recipes',
            subtitle:
                '${myRecipes.length} recipe${myRecipes.length == 1 ? '' : 's'}',
          ),
          ...myRecipes.map(
            (recipe) => _RecipeCard(
              recipe: recipe,
              onTap: () => openRecipeDetail(context, recipe),
            ),
          ),
        ],
        if (myRecipes.isNotEmpty && otherRecipes.isNotEmpty) ...[
          const SizedBox(height: 4),
          const _RecipeSectionDivider(label: 'Other recipes'),
          const SizedBox(height: 4),
        ],
        if (otherRecipes.isNotEmpty) ...[
          if (myRecipes.isEmpty)
            SectionHeader(
              title: 'Other recipes',
              subtitle:
                  '${otherRecipes.length} recipe${otherRecipes.length == 1 ? '' : 's'}',
            ),
          ...otherRecipes.map(
            (recipe) => _RecipeCard(
              recipe: recipe,
              onTap: () => openRecipeDetail(context, recipe),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecipeSectionDivider extends StatelessWidget {
  const _RecipeSectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: colorScheme.outlineVariant)),
      ],
    );
  }
}

// ── Filter Chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

// ── Recipe Card ─────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.onTap});

  final RecipeModel recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Hero(
              tag: 'recipe_image_${recipe.id}',
              child: SizedBox(
                width: 110,
                height: 110,
                child: _buildImage(colorScheme),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _InfoPill(
                            icon: Icons.kitchen_rounded,
                            label: recipe.prepTime,
                            color: Colors.orange),
                        _InfoPill(
                            icon: Icons.timer_rounded,
                            label: recipe.cookTime,
                            color: Colors.blue),
                        _InfoPill(
                            icon: Icons.people_rounded,
                            label: recipe.feeds,
                            color: Colors.purple),
                        if (recipe.isVegetarian)
                          _InfoPill(
                              icon: Icons.eco_rounded,
                              label: 'Veg',
                              color: Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Favorite button
            _FavoriteButton(recipe: recipe),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(ColorScheme cs) {
    return RecipeImage(
      imageAsset: recipe.imageAsset,
      fit: BoxFit.cover,
      width: 110,
      height: 110,
    );
  }
}

// ── Favorite Button ──────────────────────────────────────────────────────────

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.recipe});
  final RecipeModel recipe;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scale = Tween<double>(begin: 1, end: 1.4)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecipeListViewModel>();
    final uid = vm.currentUid;
    final liveRecipe = vm.recipeById(widget.recipe.id) ?? widget.recipe;
    final isFav = liveRecipe.isFavoritedBy(uid);

    return ScaleTransition(
      scale: _scale,
      child: Padding(
        padding: const EdgeInsets.only(right: 4, top: 4),
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(isFav),
              color: isFav ? Colors.redAccent : Colors.grey,
            ),
          ),
          onPressed: () async {
            _ctrl.forward().then((_) => _ctrl.reverse());
            try {
              await vm.toggleFavorite(liveRecipe);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not update favorite: $e')),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

// ── Info Pill ────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  const _InfoPill(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
