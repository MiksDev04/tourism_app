import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'router/app_router.dart';

// ─── App ──────────────────────────────────────────────────────────────────────

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'San Pablo Tourism Admin',
      debugShowCheckedModeBanner: false,

      // ── Theme ────────────────────────────────────────────────────────────────
      theme: _buildTheme(),

      // ── Routing ──────────────────────────────────────────────────────────────
      initialRoute: AppRouter.initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.dark(
        surface: AppColors.backgroundDark,
        primary: AppColors.primaryCyan,
        secondary: AppColors.primaryBlue,
        error: AppColors.accentRed,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textWhite),
        bodySmall: TextStyle(color: AppColors.textGray),
      ),
      dividerColor: AppColors.cardBorder,
    );
  }
}