import 'package:flutter/material.dart';

class ThemeState extends ChangeNotifier {
  late ThemeData _themeData;
  ThemeData get themeData => _themeData;
  double minEmissions = 0;
  double maxEmissions = 0;
  double lightness = 0.01;
  Color _seedColour = const HSLColor.fromAHSL(1, 149, 0.8, 0.01).toColor();
  Color get seedColour => _seedColour;
  final double _maxLightness = 0.5; // higher than 0.5 will wash out the colour
  final double _minLightness = 0.2;
  final _emissionThreshold =
      1000; // emission below this will have a minimum lightness
  final Map<String, double> _lastEmissionsByMode = {};
  double currentLightness = 0.01;
  bool needsCalculation = true;

  void updateTheme(List<int> emissions, int index, String mode) {
    if (index >= 0 && emissions.isNotEmpty) {
      double selectedRouteEmission = emissions[index].toDouble();

      needsCalculation = (selectedRouteEmission > 0.0);

      if (needsCalculation) {
        print("calculating lightness for $selectedRouteEmission emissions....");
        getMinMaxEmissions(emissions);
        lightness = _calculateLightness(
            selectedRouteEmission, minEmissions, maxEmissions, mode);
        currentLightness = lightness;
        _lastEmissionsByMode[mode] = selectedRouteEmission;
      } else if (selectedRouteEmission == 0.0 &&
          _lastEmissionsByMode[mode] != null) {
        lightness = _maxLightness;
        currentLightness = lightness;
      } else {
        print("NOT calculating lightness......");
        lightness = currentLightness;
      }
    }
    _themeData = _buildTheme(lightness);
    notifyListeners();
  }

  void getMinMaxEmissions(List<int> emissions) {
    final sortedEmissions = [...emissions]..sort();
    // minEmissions = sortedEmissions.first.toDouble(); // placeholder for min value
    double currentMaxEmissions = sortedEmissions.last.toDouble();

    if (maxEmissions < currentMaxEmissions) {
      maxEmissions = currentMaxEmissions;
    }
  }

// Calculate the hue lightness
  double _calculateLightness(double selectedRouteEmission, double minEmissions,
      double maxEmissions, String mode) {
    // We increase the lightness value as the emission value decreases
    // towards zero (zero emissions = brightest green)
    // but we cap the maximum lightness value at 0.5.
    // We subtract 1 to reverse the result. Without this, higher emissions
    // would result in a brighter color, which is the opposite of the desired effect.
    // If maximum emissions don't reach 1000, we cap the minimum lightness value
    // in order to avoid brown colours when the emissions are low
    if (maxEmissions == 0) {
      return lightness; // needed when the app launches for our base colour
    } else if (maxEmissions <= _emissionThreshold) {
      return _minLightness +
          (_maxLightness - _minLightness) *
              (1 -
                  (selectedRouteEmission - minEmissions) /
                      (maxEmissions - minEmissions));
    } else {
      return _maxLightness *
          (1 -
              (selectedRouteEmission - minEmissions) /
                  (maxEmissions - minEmissions));
    }
  }

  ThemeData _buildTheme(double lightness) {
    _seedColour = HSLColor.fromAHSL(1, 149, 0.8, lightness).toColor();

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColour),
      appBarTheme: AppBarTheme(
        backgroundColor: _seedColour
            .withRed(15), // add red tint to make appbar appear more brown
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
