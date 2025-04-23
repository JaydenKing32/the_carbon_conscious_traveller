import 'package:flutter/material.dart';

class ThemeState extends ChangeNotifier {
  late ThemeData _themeData;
  ThemeData get themeData => _themeData;

  double minEmissions = 0;
  double maxEmissions = 0;
  final _emissionThreshold =
      1000; // emission below this will have a minimum lightness to keep the colour scheme green

  final double _maxLightness =
      0.6; // warning: higher than 0.6 will wash out the colour
  final double _minThresholdLightness =
      0.4; // minimum value that lightness can be if the threshold is not reached
  final double _minGlobalLightness = 0.2; // minimum value that lightness can be
  double currentLightness = 0.2; // match the minGlobalLightness to start with
  final double _minGlobalSaturation = 0.25; // makes brown colours
  final double _midGlobalSaturation = 0.1; // makes mid-range colours
  double currentSaturation =
      0.25; // match the minGlobalSaturation to start with

  final double _startHue = 20; // brown
  final double _midHue = 100; // mid-range
  final double _endHue = 160; // green
  double currentHue = 20; // match the startHue to start with

  Color _seedColour = const HSLColor.fromAHSL(1, 20, 0.3, 0.2).toColor();
  Color get seedColour => _seedColour;

  final Map<String, double> _lastEmissionsByMode = {};
  bool needsCalculation = true;

  void updateTheme(List<int> emissions, int index, String mode) {
    late double hue;
    late double lightness;
    late double saturation;
    double lowerBound =
        _minGlobalLightness + 0.02; // 0.2 - 0.22 makes mid-range colours
    double upperBound =
        _minGlobalLightness + 0.05; // 0.25 and up makes green colours

    print("index is $index & emissions is $emissions");

    if (index >= 0 && emissions.isNotEmpty) {
      double selectedRouteEmission = emissions[index].toDouble();

      print(
          "selectedRouteEmission is $selectedRouteEmission for $mode &  ${_lastEmissionsByMode[mode]}");

      needsCalculation = (selectedRouteEmission > 0.0);

      if (needsCalculation) {
        print("calculating lightness for $selectedRouteEmission emissions....");
        getMinMaxEmissions(emissions);
        lightness = _calculateLightness(
            selectedRouteEmission, minEmissions, maxEmissions, mode);
        print("lightness is $lightness");
        if (lightness >= upperBound) {
          // 0.25 and up makes green colours
          print("lightness is $lightness, setting hue to 160");
          print(
              "changing hue to $_endHue & selectedRouteEmission is $selectedRouteEmission _lastEmissionsByMode[mode] $mode is ${_lastEmissionsByMode[mode]}");
          hue = _endHue;
          saturation = lightness;
        } else if (lightness >= lowerBound && lightness < upperBound) {
          // 0.22 to 0.25 makes mid range colours
          print("lightness is $lightness, setting hue to 100");
          hue = _midHue;
          saturation = _midGlobalSaturation;
        } else if (lightness <= 0.22 && lightness >= _minGlobalLightness) {
          // 0.2 - 0.22 makes brown colours
          hue = _startHue;
          saturation = _minGlobalSaturation;
        } else if (lightness == _minGlobalLightness) {
          // 0.2 or darkest colour for highest emissions
          print("lightness is $lightness, setting hue to 20");
          lightness = _minGlobalLightness;
          saturation = _minGlobalSaturation;
          hue = _startHue;
        }
        currentLightness = lightness;
        currentSaturation = saturation;
        currentHue = hue;
        // _lastEmissionsByMode[mode] = selectedRouteEmission;
      } else if (selectedRouteEmission == 0.0 &&
          currentHue == _endHue &&
          _lastEmissionsByMode[mode] != null &&
          _lastEmissionsByMode[mode] == selectedRouteEmission) {
        // this covers the edge where the selected emissions are 0
        // the issue is that the emissions list is created as soon as the travel mode button is pressed
        print(
            "changing hue to $_endHue & selectedRouteEmission is $selectedRouteEmission _lastEmissionsByMode[mode] $mode is ${_lastEmissionsByMode[mode]}");
        hue = _endHue;
        lightness = _maxLightness;
        saturation = lightness;
        currentLightness = lightness;
      } else {
        print(
            "NOT calculating lightness...... & currentLightness is $currentLightness & current hue is $currentHue & current saturation is $currentSaturation  & selectedRouteEmission is $selectedRouteEmission _lastEmissionsByMode[mode] $mode is ${_lastEmissionsByMode[mode]}");
        hue = currentHue;
        lightness = currentLightness;
        saturation = currentSaturation;
      }
      _lastEmissionsByMode[mode] = selectedRouteEmission;
      _themeData = _buildTheme(hue, saturation, lightness);
    } else {
      print("else is running");
      print(currentLightness);
      lightness = currentLightness;
      saturation = currentSaturation;
      hue = currentHue;
      _themeData = _buildTheme(hue, saturation, lightness);
    }
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
    // but we cap the maximum lightness value at 0.6.
    // We subtract 1 to reverse the result. Without this, higher emissions
    // would result in a brighter color, which is the opposite of the desired effect.
    // If maximum emissions don't reach 1000, we cap the minimum lightness value
    // in order to avoid brown colours when the emissions are low
    if (maxEmissions == 0) {
      return _minGlobalLightness; // needed when the app launches for our base colour
    } else if (maxEmissions <= _emissionThreshold) {
      return _minThresholdLightness +
          (_maxLightness - _minThresholdLightness) *
              (1 -
                  (selectedRouteEmission - minEmissions) /
                      (maxEmissions - minEmissions));
    } else {
      return _minGlobalLightness +
          (_maxLightness - _minGlobalLightness) *
              (1 -
                  (selectedRouteEmission - minEmissions) /
                      (maxEmissions - minEmissions));
    }
  }

  ThemeData _buildTheme(double hue, double saturation, double lightness) {
    print(
        "hue & lightness & Saturation in build theme: $hue & $saturation $lightness");

    _seedColour = HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();

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
