import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand - Light
  static const Color primary = Color(0xFF2E7D5B);
  static const Color primaryLight = Color(0xFFD7F0E3);

  // Backgrounds - Light
  static const Color background = Color(0xFFF7FAF8);
  static const Color surface = Color(0xFFFFFFFF);

  // Text - Light
  static const Color text = Color(0xFF1B2420);
  static const Color textSecondary = Color(0xFF5F6B66);

  // Borders - Light
  static const Color border = Color(0xFFDDE5E0);

  // Semantic
  static const Color error = Color(0xFFBA1A1A);

  // Expiry chips - Light
  static const Color expiredContainer = Color(0xFFF9EDEC);
  static const Color soon = Color(0xFF8A5100);
  static const Color soonContainer = Color(0xFFFBF2DF);
  static const Color freshContainer = Color(0xFFEEF2F1);

  // Dark Mode Palette
  static const Color primaryDark = Color(0xFF2E7D5B);
  static const Color primaryDarkContainer = Color(0xFF1B4E38);

  static const Color backgroundDark = Color(0xFF121413);
  static const Color surfaceDark = Color(0xFF1A1D1C);
  static const Color surfaceContainerDark = Color(0xFF232725);

  static const Color textDark = Color(0xFFE1E3DF);
  static const Color textSecondaryDark = Color(0xFF909A94);

  static const Color borderDark = Color(0xFF2E3531);

  static const Color errorDark = Color(0xFFE53935);

  // Expiry chips - Dark
  static const Color expiredContainerDark = Color(0xFF381515);
  static const Color onExpiredDark = Color(0xFFFF5252);
  static const Color soonDark = Color(0xFFFFB74D);
  static const Color soonContainerDark = Color(0xFF3B2700);
  static const Color freshContainerDark = Color(0xFF202724);
  static const Color onFreshDark = Color(0xFFA2ADA7);
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

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryDarkContainer,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.textSecondaryDark,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.surfaceContainerDark,
      onSecondaryContainer: AppColors.textDark,
      tertiary: AppColors.primaryDark,
      onTertiary: Colors.white,
      error: AppColors.errorDark,
      onError: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textDark,
      surfaceContainerHighest: AppColors.backgroundDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.borderDark,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.textDark,
      onInverseSurface: AppColors.surfaceDark,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      canvasColor: AppColors.backgroundDark,
      dividerColor: AppColors.borderDark,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textDark),
        bodyMedium: TextStyle(color: AppColors.textDark),
        bodySmall: TextStyle(color: AppColors.textSecondaryDark),
        titleLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.borderDark,
          disabledForegroundColor: AppColors.textSecondaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
        prefixIconColor: AppColors.textSecondaryDark,
        suffixIconColor: AppColors.textSecondaryDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorDark),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorDark, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondaryDark),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primaryDarkContainer,
        disabledColor: AppColors.backgroundDark,
        labelStyle: const TextStyle(color: AppColors.textDark),
        secondaryLabelStyle: const TextStyle(color: AppColors.primaryDark),
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primaryDarkContainer,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      extensions: const [ExpiryColors.dark],
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

  static const dark = ExpiryColors(
    expired: AppColors.expiredContainerDark,
    onExpired: AppColors.onExpiredDark,
    soon: AppColors.soonContainerDark,
    onSoon: AppColors.soonDark,
    fresh: AppColors.freshContainerDark,
    onFresh: AppColors.onFreshDark,
  );

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
