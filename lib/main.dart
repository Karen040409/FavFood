import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'screens/album_page.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_page.dart';
import 'screens/recipe_list_screen.dart';
import 'screens/json_page.dart';
import 'screens/settings_page.dart';
import 'styles.dart';
import 'theme/app_theme.dart';
import 'viewmodels/album_list_view_model.dart';
import 'viewmodels/recipe_list_view_model.dart';
import 'widgets/app_logo.dart';
import 'widgets/user_avatar.dart';

/// ─── REPLACE THIS WITH YOUR REAL WEB CLIENT ID ───────────────────────────
/// How to get it:
///  1. Go to: https://console.firebase.google.com → your project → Authentication
///  2. Click "Sign-in method" tab → click "Google" row → expand it
///  3. Copy the "Web client ID" under "Web SDK configuration"
/// Format:  1086355063575-XXXXXXXXXXXX.apps.googleusercontent.com
const _googleWebClientId =
    'PASTE_YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    GoogleProvider(clientId: _googleWebClientId),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RecipeListViewModel()),
        ChangeNotifierProvider(create: (context) => AlbumListViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Fav Food',
      theme: AppTheme.light(),
      home: const AuthGate(webClientId: _googleWebClientId),
    );
  }
}

class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: pageBackgroundDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: [
              const AppLogo(size: 36, showBackground: false, backgroundPadding: 0),
              const SizedBox(width: 10),
              const Text('My Fav Food'),
            ],
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.headerGradient(cs),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Profile',
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<ProfileScreen>(
                    builder: (context) => ProfileScreen(
                      appBar: AppBar(title: const Text('User Profile')),
                      avatar: const AuthUserAvatar(radius: 56),
                      actions: [
                        SignedOutAction((context) {
                          Navigator.of(context).pop();
                        }),
                      ],
                      children: const [
                        Divider(),
                      ],
                    ),
                  ),
                );
              },
            ),
            Consumer<RecipeListViewModel>(
              builder: (context, listViewModel, child) => Padding(
                padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                child: Badge(
                  label: Text('${listViewModel.favoriteCount}'),
                  isLabelVisible: listViewModel.favoriteCount > 0,
                  backgroundColor: cs.primary,
                  child: IconButton.filledTonal(
                    tooltip: 'Favorite food',
                    icon: const Icon(Icons.favorite_rounded),
                    color: AppColors.accentRose,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: const [
              Tab(icon: Icon(Icons.home_rounded), text: 'Home'),
              Tab(icon: Icon(Icons.restaurant_menu_rounded), text: 'Recipes'),
              Tab(icon: Icon(Icons.album_rounded), text: 'Album'),
              Tab(icon: Icon(Icons.data_object_rounded), text: 'JSON'),
              Tab(icon: Icon(Icons.settings_rounded), text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            HomePage(
              onBrowseRecipes: () => _tabController.animateTo(1),
              onOpenSettings: () => _tabController.animateTo(4),
            ),
            const RecipeListScreen(),
            const AlbumPage(),
            const JsonPage(),
            const SettingsPage(),
          ],
        ),
        floatingActionButton: _tabController.index == 2 ? const AlbumPageFab() : null,
      ),
    );
  }
}
