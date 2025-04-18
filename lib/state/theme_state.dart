import 'package:flutter/material.dart';

class ThemeState extends ChangeNotifier {
  ThemeData _themeData = ThemeData.light();
  ThemeData get themeData => _themeData;
  double min = 0;
  double max = 0;
  double lightness = 0.05;
  Color _seedColour = const HSLColor.fromAHSL(1, 149, 0.8, 0.1).toColor();
  Color get seedColour => _seedColour;

  void updateTheme(List<int> emissions, int index, String mode) {
    print("index $index");
    print("mode $mode");

    if (index >= 0 && emissions.isNotEmpty) {
      double selectedRouteEmission = emissions[index].toDouble();
      getMinMaxEmissions(emissions);
      lightness = _calculateLightness(selectedRouteEmission, min, max, mode);
    }

    print(
        "calculate lightness next. These are the emissions length: ${emissions.length}");
    print("lightness = $lightness");

    _themeData = _buildTheme(lightness);
    notifyListeners();
  }

  void getMinMaxEmissions(List<int> emissions) {
    final sortedEmissions = [...emissions]..sort();
    min = min; // placeholder for min value

    if (max < sortedEmissions.last.toDouble()) {
      max = sortedEmissions.last.toDouble();
    }

    print("min $min");
    print("max $max");
  }

// Calculate the hue lightness
  double _calculateLightness(
      double selectedRouteEmission, double min, double max, String mode) {
    if (max == 0) {
      return lightness; // needed when the app launches for our base colour
    } else {
      /* we increase lightness value as the emission value decreases
       towards zero (zero emissions = brightest green)
       but we cap the lightness value at 0.5*/
      double maximumLightness = 0.5;
      return maximumLightness *
          (1 -
              (selectedRouteEmission - min) /
                  (max -
                      min)); // substract 1 to reverse the result (otherwise, higher emissions would be brighter)
    }
  }

  ThemeData _buildTheme(double lightness) {
    _seedColour = HSLColor.fromAHSL(1, 149, 0.8, lightness).toColor();

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
