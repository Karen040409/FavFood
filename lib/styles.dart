import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

const descTextStyle = TextStyle(
  fontWeight: FontWeight.w700,
  letterSpacing: 0.2,
  fontSize: 16,
  height: 1.5,
);

/// Soft page background used behind tab content.
BoxDecoration pageBackgroundDecoration(BuildContext context) {
  return BoxDecoration(
    gradient: AppTheme.primaryGradient(Theme.of(context).colorScheme),
  );
}
