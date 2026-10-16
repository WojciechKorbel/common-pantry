import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2E7D5B);
  static const Color primaryLight = Color(0xFFD7F0E3);

  // Backgrounds
  static const Color background = Color(0xFFF7FAF8);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color text = Color(0xFF1B2420);
  static const Color textSecondary = Color(0xFF5F6B66);

  // Borders and separators
  static const Color border = Color(0xFFDDE5E0);

  // Additional semantic colors
  static const Color error = Color(0xFFBA1A1A);

  // Expiry chips colors
  static const expiredContainer = Color(0xFFF9EDEC);
  static const soon = Color(0xFF8A5100);
  static const soonContainer = Color(0xFFFBF2DF);
  static const freshContainer = Color(0xFFEEF2F1);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.text,
      secondary: AppColors.textSecondary,
      onSecondary: AppColors.surface,
      secondaryContainer: AppColors.primaryLight,
      onSecondaryContainer: AppColors.text,
      tertiary: AppColors.primary,
      onTertiary: AppColors.surface,
      error: AppColors.error,
      onError: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      surfaceContainerHighest: AppColors.background,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.text,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,

      // Text
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.text),
        bodyMedium: TextStyle(color: AppColors.text),
        bodySmall: TextStyle(color: AppColors.textSecondary),
        titleLarge: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
        ),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // Separators
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Icons
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        disabledColor: AppColors.background,
        labelStyle: const TextStyle(color: AppColors.text),
        secondaryLabelStyle: const TextStyle(color: AppColors.primary),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Bottom navigation
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12),
        ),
      ),

      // Floating action button (+)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),

      extensions: const [ExpiryColors.light],
    );
  }
}

/// Colours of expiry chips
@immutable
class ExpiryColors extends ThemeExtension<ExpiryColors> {
  const ExpiryColors({
    required this.expired,
    required this.onExpired,
    required this.soon,
    required this.onSoon,
    required this.fresh,
    required this.onFresh,
  });

  static const light = ExpiryColors(
    expired: AppColors.expiredContainer,
    onExpired: AppColors.error,
    soon: AppColors.soonContainer,
    onSoon: AppColors.soon,
    fresh: AppColors.freshContainer,
    onFresh: AppColors.textSecondary,
  );

  /// Backgrounds.
  final Color expired;
  final Color soon;
  final Color fresh;

  /// Text and icons on those backgrounds.
  final Color onExpired;
  final Color onSoon;
  final Color onFresh;

  @override
  ExpiryColors copyWith({
    Color? expired,
    Color? onExpired,
    Color? soon,
    Color? onSoon,
    Color? fresh,
    Color? onFresh,
  }) => ExpiryColors(
    expired: expired ?? this.expired,
    onExpired: onExpired ?? this.onExpired,
    soon: soon ?? this.soon,
    onSoon: onSoon ?? this.onSoon,
    fresh: fresh ?? this.fresh,
    onFresh: onFresh ?? this.onFresh,
  );

  @override
  ExpiryColors lerp(ExpiryColors? other, double t) {
    if (other == null) {
      return this;
    }
    return ExpiryColors(
      expired: Color.lerp(expired, other.expired, t)!,
      onExpired: Color.lerp(onExpired, other.onExpired, t)!,
      soon: Color.lerp(soon, other.soon, t)!,
      onSoon: Color.lerp(onSoon, other.onSoon, t)!,
      fresh: Color.lerp(fresh, other.fresh, t)!,
      onFresh: Color.lerp(onFresh, other.onFresh, t)!,
    );
  }
}
