import 'package:flutter/material.dart';

const appLogoAsset = 'images/logo.png';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 88,
    this.showBackground = true,
    this.backgroundPadding = 14,
  });

  final double size;
  final bool showBackground;
  final double backgroundPadding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final image = Image.asset(
      appLogoAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.restaurant_menu_rounded,
        size: size * 0.72,
        color: cs.primary,
      ),
    );

    if (!showBackground) return image;

    return Container(
      padding: EdgeInsets.all(backgroundPadding),
      decoration: BoxDecoration(
        color: cs.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: image,
    );
  }
}
