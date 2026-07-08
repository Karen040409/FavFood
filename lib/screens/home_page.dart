import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/profile_photo_service.dart';
import '../theme/app_theme.dart';
import '../viewmodels/recipe_list_view_model.dart';
import '../widgets/kitchen_chat_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/user_avatar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onBrowseRecipes, this.onOpenSettings});

  final VoidCallback? onBrowseRecipes;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    final cs = Theme.of(context).colorScheme;
    final recipeVm = context.watch<RecipeListViewModel>();
    final displayName = user?.displayName?.trim();
    final greeting = displayName != null && displayName.isNotEmpty
        ? 'Welcome back, ${displayName.split(' ').first}!'
        : 'Welcome!';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: AppTheme.glassCard(cs),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.primary.withValues(alpha: 0.25), width: 3),
                    ),
                    child: AuthUserAvatar(
                      radius: 58,
                      showEditBadge: true,
                      onTap: () => ProfilePhotoService.instance.pickAndUpload(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => ProfilePhotoService.instance.pickAndUpload(context),
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('Upload profile photo'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    greeting,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'Discover recipes, save your favorites, and adjust serving sizes with one tap.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: cs.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Your kitchen at a glance',
              subtitle: 'Live stats from your recipe collection',
            ),
            Row(
              children: [
                StatCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Recipes',
                  value: '${recipeVm.recipeCount}',
                  color: cs.primary,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.favorite_rounded,
                  label: 'Favorites',
                  value: '${recipeVm.favoriteCount}',
                  color: AppColors.accentRose,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.eco_rounded,
                  label: 'Vegetarian',
                  value: '${recipeVm.vegetarianCount}',
                  color: AppColors.accentSage,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Quick actions'),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onBrowseRecipes,
                    icon: const Icon(Icons.restaurant_menu_rounded),
                    label: const Text('Browse Recipes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_rounded),
                    label: const Text('Settings'),
                  ),
                ),
              ],
            ),
            const KitchenChatCard(),
          ],
        ),
      ),
    );
  }
}
