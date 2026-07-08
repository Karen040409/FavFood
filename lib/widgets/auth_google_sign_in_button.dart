import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';

class AuthGoogleSignInButton extends StatelessWidget {
  const AuthGoogleSignInButton({
    super.key,
    required this.clientId,
    required this.action,
  });

  final String clientId;
  final AuthAction action;

  @override
  Widget build(BuildContext context) {
    final provider = GoogleProvider(clientId: clientId);
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final googleIcon = provider.style.iconWidget.getValue(brightness);

    return AuthFlowBuilder<OAuthController>(
      provider: provider,
      action: action,
      builder: (context, state, ctrl, child) {
        final isLoading = state is SigningIn || state is CredentialReceived;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    cs.surface,
                    cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  ],
                ),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : () => ctrl.signIn(Theme.of(context).platform),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLoading)
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: cs.primary,
                            ),
                          )
                        else ...[
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
                            ),
                            alignment: Alignment.center,
                            child: SizedBox(width: 18, height: 18, child: googleIcon),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.15,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (state is AuthFailed)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ErrorText(exception: state.exception),
              ),
          ],
        );
      },
    );
  }
}

class AuthSignInFooter extends StatelessWidget {
  const AuthSignInFooter({
    super.key,
    required this.clientId,
    required this.action,
  });

  final String clientId;
  final AuthAction action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'By signing in, you agree to our terms and conditions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: cs.outline,
            ),
          ),
          const SizedBox(height: 14),
          AuthGoogleSignInButton(clientId: clientId, action: action),
        ],
      ),
    );
  }
}
