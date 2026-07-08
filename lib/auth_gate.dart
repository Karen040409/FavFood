import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'theme/app_theme.dart';
import 'widgets/app_logo.dart';
import 'widgets/auth_google_sign_in_button.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.webClientId});

  /// The Web Client ID from:
  /// Firebase Console → Authentication → Sign-in method → Google
  /// → (expand Google row) → Web SDK configuration → Web client ID
  final String webClientId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient(Theme.of(context).colorScheme),
            ),
            child: SignInScreen(
              providers: [
                EmailAuthProvider(),
              ],
              subtitleBuilder: (context, action) {
                final isWideLayout = MediaQuery.sizeOf(context).width > 800;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      if (!isWideLayout) ...[
                        const AppLogo(size: 72, backgroundPadding: 12),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        'My Fav Food',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        action == AuthAction.signIn
                            ? 'Welcome to FavFood, please sign in!'
                            : 'Welcome to FavFood, please sign up!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
              footerBuilder: (context, action) {
                return AuthSignInFooter(
                  clientId: webClientId,
                  action: action,
                );
              },
              sideBuilder: (context, shrinkOffset) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppLogo(size: 140, showBackground: false),
                      const SizedBox(height: 24),
                      Text(
                        'Cook smarter.\nSave faster.',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -0.8,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your personal recipe book with favorites, scaling, and cloud sync.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        return const MainTabController();
      },
    );
  }
}
