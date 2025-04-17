import 'package:flutter/material.dart';

class ThemeState extends ChangeNotifier {
  ThemeData _themeData = ThemeData.light();
  ThemeData get themeData => _themeData;
  double min = 0;
  double max = 0;
  double lightness = 0.05;

  void getMinMaxEmissions(List<int> emissions) {
    final sortedEmissions = [...emissions]..sort();
    min = sortedEmissions.first.toDouble();
    max = sortedEmissions.last.toDouble();
    print("min $min");
    print("max $max");
  }

  void updateTheme(List<int> emissions, int index, String mode) {
    print("index $index");
    print("mode $mode");
    if (index >= 0 && emissions.isNotEmpty) {
      double selectedRouteEmission = emissions[index].toDouble();
      getMinMaxEmissions(emissions);
      lightness = _calculateLightness(selectedRouteEmission, min, max);
    }
    print(
        "calculate lightness next. These are the emissions length: ${emissions.length}");

    print("lightness = $lightness");
    _themeData = _buildTheme(lightness);
    notifyListeners();
  }

// Calculate the hue lightness
  double _calculateLightness(double result, double min, double max) {
    if (min == max) {
      return 0.05;
    } else {
      return 0.5 * (1 - (result - min) / (max - min));
    }
  }

  ThemeData _buildTheme(double lightness) {
    final seedColour = HSLColor.fromAHSL(1, 149, 0.8, lightness).toColor();

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seedColour),
      appBarTheme: AppBarTheme(
        backgroundColor: seedColour,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 24),
        displayMedium: TextStyle(fontSize: 20),
        displaySmall: TextStyle(fontSize: 16),
        bodyLarge: TextStyle(fontSize: 18),
        bodyMedium: TextStyle(fontSize: 16),
        bodySmall: TextStyle(
          fontSize: 20,
          //color: Color.fromARGB(255, 125, 125, 125),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      useMaterial3: true,
    );
  }
}
