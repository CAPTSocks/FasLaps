import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,

        iconTheme: IconThemeData(color: AppColors.textPrimary),

        actionsIconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          shape: const CircleBorder(),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: AppColors.primary,

          minimumSize: const Size(0, 70),

          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),

          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),

        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      switchTheme: SwitchThemeData(
        // Color of the circular knob
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary; // Active knob color
          }
          return AppColors.primary; // Inactive knob color
        }),

        // Color of the background pill/track
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary; // Active track color
          }
          return AppColors.secondary; // Inactive track color
        }),

        // Outline border around the track
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return const Color.fromARGB(255, 231, 224, 219);
        }),
        trackOutlineWidth: const WidgetStatePropertyAll(2.0),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color.fromARGB(100, 31, 44, 61),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: const TextStyle(color: AppColors.textPrimary),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        // Default border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        // Border when the user taps into the field
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
      ),
      // Controls the style of the actual text typed by the user (Material 3)

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.textPrimary,
        selectionColor: AppColors.secondary,
        selectionHandleColor: AppColors.secondary,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.secondaryGradiant,
        inactiveTrackColor: AppColors.primaryGradiant,
        thumbColor: AppColors.secondary,
        overlayColor: AppColors.primary.withOpacity(0.2),
        valueIndicatorColor: AppColors.secondary,
      ),
    );
  }
}
