import 'package:flutter/material.dart';

class ThemeState extends ChangeNotifier {
  late ThemeData _themeData = _buildTheme();
  ThemeData get themeData => _themeData;

  final HSLColor _startColour = const HSLColor.fromAHSL(1, 110, 0.75, 0.95);
  final HSLColor _endColour = const HSLColor.fromAHSL(1, 107, 0.64, 0.48);

  Color _seedColour = const HSLColor.fromAHSL(1, 0, 0, 0).toColor();
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

    t = (selectedRouteEmission - minEmissions) / (maxEmissions - minEmissions);
    print("t value in else block: $t");

    t = t.clamp(0.0, 1.0);
    print("Final t value after clamping: $t");

    Color newColour = HSLColor.lerp(_endColour, _startColour, t)!.toColor();
    _seedColourList[activeRouteIndex] = newColour;

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
    notifyListeners();
  }

  void resetThemeColour() {
    _seedColourList.clear();
    notifyListeners();
  }

  ThemeData _buildTheme() {
    HSLColor hslColour = HSLColor.fromColor(_seedColour);

    if (hslColour.lightness > 0.8) {
      _isTooLight = true;
    } else {
      _isTooLight = false;
    }

    // Initial theme data
    ThemeData themeData1 = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColour),
      appBarTheme: AppBarTheme(
        backgroundColor: _seedColour,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Colors.white,
          opacity: 1,
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
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColour),
      appBarTheme: AppBarTheme(
        backgroundColor: _seedColour,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.black,
          opacity: 1,
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
      iconTheme: const IconThemeData(
        color: Colors.black,
      ),
      useMaterial3: true,
    );

    // Theme data for the rest of the cases
    ThemeData themeData3 = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColour),
      appBarTheme: AppBarTheme(
        backgroundColor: _seedColour,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.black,  
          opacity: 1,
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
      iconTheme: const IconThemeData(
        color: Colors.black ,
      ),
      useMaterial3: true,
    );

    if (hslColour.lightness == 0) {
      print("theme is black & hsl is $hslColour");
      return themeData1;
    } else if (hslColour.lightness > 0.8) {
      print("theme is brown & hsl is $hslColour");
      return themeData2;
    } else {
      print("theme is seedcolour & hsl is $hslColour");
      return themeData3;
    }

    // return ThemeData(
    //   colorScheme: ColorScheme.fromSeed(seedColor: _seedColour),
    //   appBarTheme: AppBarTheme(
    //     backgroundColor: _seedColour,
    //     foregroundColor: Colors.white,
    //     iconTheme: const IconThemeData(
    //       color: Colors.white,
    //       opacity: 1,
    //     ),
    //   ),
    //   textTheme: const TextTheme(
    //     displayLarge: TextStyle(fontSize: 24),
    //     displayMedium: TextStyle(fontSize: 20),
    //     displaySmall: TextStyle(fontSize: 16),
    //     bodyLarge: TextStyle(fontSize: 18),
    //     bodyMedium: TextStyle(fontSize: 16),
    //     bodySmall: TextStyle(fontSize: 20),
    //     titleLarge: TextStyle(
    //       fontSize: 20,
    //       fontWeight: FontWeight.bold,
    //     ),
    //   ),
    //   filledButtonTheme: FilledButtonThemeData(
    //     style: FilledButton.styleFrom(
    //       backgroundColor: _seedColour,
    //       foregroundColor: Colors.white,
    //       textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    //     ),
    //   ),
    //   useMaterial3: true,
    // );
  }
}
