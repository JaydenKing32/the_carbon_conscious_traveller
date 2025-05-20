import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class ThemeState extends ChangeNotifier {
  late ThemeData _themeData = _buildTheme();
  ThemeData get themeData => _themeData;

  final HSLColor _startColour =
      const HSLColor.fromAHSL(1, 107, 0.64, 0.48); // bright green
  final HSLColor _endColour =
      const HSLColor.fromAHSL(1, 110, 0.75, 0.95); // light green

  Color _seedColour = const HSLColor.fromAHSL(1, 0, 0, 0).toColor(); // black
  Color get seedColour => _seedColour;
  List<Color> _seedColourList = [];
  List<Color> get seedColourList => _seedColourList;

  List<Color> _transitColours = [];
  List<Color> _motoColours = [];
  List<Color> _carColours = [];
  List<Color> get transitColourList => _transitColours;
  List<Color> get motoColourList => _motoColours;
  List<Color> get carColourList => _carColours;

  bool _isTooLight = false;
  bool get isTooLight => _isTooLight;

  bool needsCalculation = true;

  double currentMaxEmissions = 0;
  double currentMinEmissions = 0;

  calculateColour(minEmissions, maxEmissions, selectedRouteEmission,
      int activeRouteIndex, int totalRouteCount, String mode) {
    double t = 0;

    // Ensure the list is exactly the right length
    if (_seedColourList.length != totalRouteCount) {
      _seedColourList =
          List<Color>.filled(totalRouteCount, _startColour.toColor());
    }

    if (totalRouteCount == 1) {
      _seedColourList[activeRouteIndex] = _endColour.toColor();
    } else {
      t = (selectedRouteEmission - minEmissions) /
          (maxEmissions - minEmissions);
      print("t value in else block: $t");

      t = t.clamp(0.0, 1.0);
      print("Final t value after clamping: $t");

      Color newColour = HSLColor.lerp(_startColour, _endColour, t)!.toColor();
      _seedColourList[activeRouteIndex] = newColour;
    }

    if (mode == 'driving') {
      _carColours = [];
      _carColours.addAll(_seedColourList);
    } else if (mode == 'motorcycling') {
      _motoColours = [];
      _motoColours.addAll(_seedColourList);
    } else if (mode == 'transit') {
      _transitColours = [];
      _transitColours.addAll(_seedColourList);
    }
    notifyListeners();
  }

  void setThemeColour(activeRouteIndex) {
    _seedColour = _seedColourList[activeRouteIndex];
    _themeData = _buildTheme();
    // We need this to ensure the theme is rebuilt
    // when a polyline is tapped. Otherwise, the theme
    // does not update immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void resetThemeColour() {
    _seedColourList.clear();
    notifyListeners();
  }

  ThemeData _buildTheme() {
    HSLColor hslColour = HSLColor.fromColor(_seedColour);
    double lightnessLimit =
        0.8; // value of lightness when green becomes too light

    if (hslColour.lightness > lightnessLimit) {
      _isTooLight = true;
    } else {
      _isTooLight = false;
    }

    // Initial theme data
    ThemeData themeData1 = ThemeData(
      fontFamily: GoogleFonts.quicksand(
          fontWeight: FontWeight.w600,
      ).fontFamily,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xff000000),
        surfaceTint: Color(0xff5e5e5e),
        onPrimary: Color(0xffffffff),
        primaryContainer: Color(0xff1b1b1b),
        onPrimaryContainer: Color(0xff848484),
        secondary: Color(0xff5e5e5e),
        onSecondary: Color(0xffffffff),
        secondaryContainer: Color(0xffe2e2e2),
        onSecondaryContainer: Color(0xff646464),
        tertiary: Color(0xff000000),
        onTertiary: Color(0xffffffff),
        tertiaryContainer: Color(0xff1b1b1b),
        onTertiaryContainer: Color(0xff848484),
        error: Color(0xffba1a1a),
        onError: Color(0xffffffff),
        errorContainer: Color(0xffffdad6),
        onErrorContainer: Color(0xff93000a),
        surface: Color(0xfff9f9f9),
        onSurface: Color(0xff1b1b1b),
        onSurfaceVariant: Color(0xff4c4546),
        outline: Color(0xff7e7576),
        outlineVariant: Color(0xffcfc4c5),
        shadow: Color(0xff000000),
        scrim: Color(0xff000000),
        inverseSurface: Color(0xff303030),
        inversePrimary: Color(0xffc6c6c6),
        primaryFixed: Color(0xffe2e2e2),
        onPrimaryFixed: Color(0xff1b1b1b),
        primaryFixedDim: Color(0xffc6c6c6),
        onPrimaryFixedVariant: Color(0xff474747),
        secondaryFixed: Color(0xffe2e2e2),
        onSecondaryFixed: Color(0xff1b1b1b),
        secondaryFixedDim: Color(0xffc6c6c6),
        onSecondaryFixedVariant: Color(0xff474747),
        tertiaryFixed: Color(0xffe2e2e2),
        onTertiaryFixed: Color(0xff1b1b1b),
        tertiaryFixedDim: Color(0xffc6c6c6),
        onTertiaryFixedVariant: Color(0xff474747),
        surfaceDim: Color(0xffdadada),
        surfaceBright: Color(0xfff9f9f9),
        surfaceContainerLowest: Color(0xffffffff),
        surfaceContainerLow: Color(0xfff3f3f3),
        surfaceContainer: Color(0xffeeeeee),
        surfaceContainerHigh: Color(0xffe8e8e8),
        surfaceContainerHighest: Color(0xffe2e2e2),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: _seedColour,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Colors.white,
          opacity: 1,
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 24),
        displayMedium: TextStyle(fontSize: 20),
        displaySmall: TextStyle(fontSize: 16),
        bodyLarge: TextStyle(fontSize: 18),
        bodyMedium: TextStyle(fontSize: 16),
        bodySmall: TextStyle(fontSize: 20),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _seedColour,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: Colors.grey,
        selectedColor: Colors.black,
        fillColor: Colors.transparent,
        highlightColor: Colors.black.withAlpha(50),
      ),
      useMaterial3: true,
    );

    // Theme data for when calculated colours are too light
    // Lightness > 0.8
    ThemeData themeData2 = ThemeData(
      fontFamily: GoogleFonts.quicksand(
          fontWeight: FontWeight.w600,
      ).fontFamily,
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColour),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: _seedColour,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.black,
          opacity: 1,
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 24),
        displayMedium: TextStyle(fontSize: 20),
        displaySmall: TextStyle(fontSize: 16),
        bodyLarge: TextStyle(fontSize: 18),
        bodyMedium: TextStyle(fontSize: 16),
        bodySmall: TextStyle(fontSize: 20),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: Colors.grey,
        selectedColor: Colors.black,
        fillColor: Colors.transparent,
        highlightColor: Colors.black.withAlpha(50),
      ),
      iconTheme: const IconThemeData(
        color: Colors.black,
      ),
      useMaterial3: true,
    );

    // Theme data for the rest of the cases
    ThemeData themeData3 = ThemeData(
      fontFamily: GoogleFonts.quicksand(
          fontWeight: FontWeight.w600,
      ).fontFamily,
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColour),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: _seedColour,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.black,
          opacity: 1,
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 24),
        displayMedium: TextStyle(fontSize: 20),
        displaySmall: TextStyle(fontSize: 16),
        bodyLarge: TextStyle(fontSize: 18),
        bodyMedium: TextStyle(fontSize: 16),
        bodySmall: TextStyle(fontSize: 20),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: Colors.grey,
        selectedColor: Colors.black,
        fillColor: Colors.transparent,
        highlightColor: Colors.black.withAlpha(50),
      ),
      iconTheme: const IconThemeData(
        color: Colors.black,
      ),
      useMaterial3: true,
    );

    if (hslColour.lightness == 0) {
      print("theme is black & hsl is $hslColour");
      return themeData1;
    } else if (hslColour.lightness > lightnessLimit) {
      print("theme is brown & hsl is $hslColour");
      return themeData2;
    } else {
      print("theme is seedcolour & hsl is $hslColour");
      return themeData3;
    }
  }
}
