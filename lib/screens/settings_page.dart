import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/profile_photo_service.dart';
import '../theme/app_theme.dart';
import '../viewmodels/recipe_list_view_model.dart';
import '../widgets/app_logo.dart';
import '../widgets/user_avatar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _recipeReminders = true;
  bool _isUploadingPhoto = false;

  Future<void> _changePhoto() async {
    setState(() => _isUploadingPhoto = true);
    await ProfilePhotoService.instance.pickAndUpload(context);
    if (mounted) setState(() => _isUploadingPhoto = false);
  }

  @override
  Widget build(BuildContext context) {
    final listViewModel = context.watch<RecipeListViewModel>();
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            if (user != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.glassCard(cs),
                child: Row(
                  children: [
                    AuthUserAvatar(
                      radius: 34,
                      showEditBadge: !_isUploadingPhoto,
                      onTap: _isUploadingPhoto ? null : _changePhoto,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? 'Signed in',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                          ),
                          const SizedBox(height: 4),
                          Text(user.email ?? '', style: TextStyle(color: cs.onSurfaceVariant)),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _isUploadingPhoto ? null : _changePhoto,
                            icon: _isUploadingPhoto
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: cs.primary,
                                    ),
                                  )
                                : const Icon(Icons.upload_rounded, size: 18),
                            label: Text(_isUploadingPhoto ? 'Uploading…' : 'Change photo'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            _SettingsGroup(
              title: 'Recipes',
              children: [
                const ListTile(
                  leading: Icon(Icons.eco_rounded),
                  title: Text('Vegetarian Filter'),
                  subtitle: Text('Use the filter chips on the Recipes tab'),
                  enabled: false,
                ),
                SwitchListTile(
                  title: const Text('Recipe reminders'),
                  subtitle: const Text('Notify me about new recipes'),
                  value: _recipeReminders,
                  onChanged: (value) => setState(() => _recipeReminders = value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'App',
              children: [
                const ListTile(
                  leading: AppLogo(size: 40, showBackground: false, backgroundPadding: 0),
                  title: Text('About My Fav Food'),
                  subtitle: Text('Version 1.0.0'),
                ),
                ListTile(
                  leading: Icon(Icons.favorite_rounded, color: AppColors.accentRose),
                  title: const Text('Saved favorites'),
                  subtitle: Text('${listViewModel.favoriteCount} recipe(s)'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: SignOutButton(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}
