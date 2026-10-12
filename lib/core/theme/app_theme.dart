import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Radios del sistema: tarjetas 24–28, campos 18, píldoras totalmente redondas.
abstract final class AppRadius {
  static const pill = 999.0;
  static const card = 24.0;
  static const hero = 28.0;
  static const field = 18.0;
  static const tile = 20.0;
}

abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.blush,
      onPrimaryContainer: AppColors.primaryDeep,
      secondary: AppColors.ink,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.blush,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.wine,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.wine,
      outline: AppColors.outline,
      outlineVariant: AppColors.border,
      surfaceContainerHighest: AppColors.blush,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: 'Lato',
      splashFactory: InkSparkle.splashFactory,
    );

    OutlineInputBorder border(Color color, [double width = 0]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: width == 0
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'Lato',
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.h2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blush,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: AppText.body.copyWith(color: AppColors.wine),
        labelStyle: AppText.caption,
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(AppColors.primary, 2),
        errorBorder: border(AppColors.error, 2),
        focusedErrorBorder: border(AppColors.error, 2),
        errorStyle: AppText.caption.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.body.copyWith(color: AppColors.white),
        actionTextColor: AppColors.blush,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.hero),
        ),
        titleTextStyle: AppText.h2,
        contentTextStyle: AppText.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.hero),
          ),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.white,
        hourMinuteColor: AppColors.blush,
        dialHandColor: AppColors.primary,
        dialBackgroundColor: AppColors.blush,
        entryModeIconColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.hero),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionHandleColor: AppColors.primary,
      ),
    );
  }
}
