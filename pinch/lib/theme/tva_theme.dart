import 'package:flutter/material.dart';

import 'tva_colors.dart';

class TvaTheme {
  TvaTheme._();

  static ThemeData get dark {
    const mono = TextStyle(fontFamily: 'IBMPlexMono');
    const sans = TextStyle(fontFamily: 'IBMPlexSans');

    final textTheme = TextTheme(
      headlineLarge: sans.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: TvaColors.clawd,
        letterSpacing: 3,
      ),
      headlineMedium: sans.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: TvaColors.txt,
        letterSpacing: 1,
      ),
      bodyLarge: sans.copyWith(
        fontSize: 13,
        color: TvaColors.txt,
      ),
      bodyMedium: sans.copyWith(
        fontSize: 12,
        color: TvaColors.txt2,
      ),
      bodySmall: sans.copyWith(
        fontSize: 11,
        color: TvaColors.txt3,
      ),
      labelLarge: mono.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: TvaColors.txt2,
        letterSpacing: 1.5,
      ),
      labelMedium: mono.copyWith(
        fontSize: 10,
        color: TvaColors.txt3,
        letterSpacing: 2,
      ),
      labelSmall: mono.copyWith(
        fontSize: 8,
        fontWeight: FontWeight.w500,
        color: TvaColors.txt3,
        letterSpacing: 3,
      ),
    );

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: TvaColors.bg,
      canvasColor: TvaColors.bg,
      cardColor: TvaColors.bgPanel,
      dividerColor: TvaColors.brd,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: TvaColors.clawd,
        secondary: TvaColors.amber,
        error: TvaColors.rust,
        surface: TvaColors.bgPanel,
      ),
      textTheme: textTheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        filled: true,
        fillColor: TvaColors.bgInset,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(TvaColors.brdAc),
        trackColor: WidgetStateProperty.all(TvaColors.bgInset),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }
}
