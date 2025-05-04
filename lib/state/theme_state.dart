import 'package:flutter/material.dart';

class ThemeState extends ChangeNotifier {
  late ThemeData _themeData = _buildTheme();
  ThemeData get themeData => _themeData;

  final HSLColor _startColour = const HSLColor.fromAHSL(1, 110, 0.75, 0.95);
  final HSLColor _endColour = const HSLColor.fromAHSL(1, 107, 0.64, 0.48);

  Color _seedColour = const HSLColor.fromAHSL(1, 230, 1, 0).toColor();
  Color get seedColour => _seedColour;
  List<Color> _seedColourList = [];
  List<Color> get seedColourList => _seedColourList;

  List<Color> _transitColours = [];
  List<Color> _motoColours = [];
  List<Color> _carColours = [];
  List<Color> get transitColourList => _transitColours;
  List<Color> get motoColourList => _motoColours;
  List<Color> get carColourList => _carColours;

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
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColour),
      appBarTheme: AppBarTheme(
        backgroundColor: _seedColour,
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
      useMaterial3: true,
    );
  }
}
