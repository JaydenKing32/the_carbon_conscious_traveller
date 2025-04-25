import 'package:flutter/material.dart';

class ThemeState extends ChangeNotifier {
  late ThemeData _themeData;
  ThemeData get themeData => _themeData;

  double minEmissions = 0;
  double maxEmissions = 0;
  final _minEmissionThreshold =
      5000; // emissions below this will have a minimum t value to keep the colour scheme green
  final _maxEmissionThreshold =
      29000; // emissions above this will have a maximum t valye to keep the colour scheme not too green

  final HSLColor _startColour = const HSLColor.fromAHSL(1, 20, 0.3, 0.2);
  final HSLColor _endColour = const HSLColor.fromAHSL(1, 107, 0.60, 0.53);

  Color _seedColour = const HSLColor.fromAHSL(1, 230, 1, 0).toColor();
  Color get seedColour => _seedColour;

  final Map<String, double> _lastEmissionsByMode = {};
  bool needsCalculation = true;

  double currentMaxEmissions = 0;
  double currentMinEmissions = 0;

  void updateTheme(List<int> emissions, int index, String mode) {
    print("index is $index & emissions is $emissions");

    if (index >= 0 && emissions.isNotEmpty) {
      double selectedRouteEmission = emissions[index].toDouble();

      print(
          "selectedRouteEmission is $selectedRouteEmission for $mode &  ${_lastEmissionsByMode[mode]}");

      needsCalculation = (selectedRouteEmission > 0.0);

      if (needsCalculation) {
        print("calculating colour for $selectedRouteEmission emissions....");
        getMinMaxEmissions(emissions);
        _seedColour = calculateColour(
            currentMinEmissions, currentMaxEmissions, selectedRouteEmission);
      } else {
        print("NOT calculating colour");
        return;
      }
      _themeData = _buildTheme();
    } else {
      _themeData = _buildTheme();
    }
    notifyListeners();
  }

  void getMinMaxEmissions(List<int> emissions) {
    final sortedEmissions = [...emissions]..sort();
    minEmissions = sortedEmissions.first.toDouble();
    maxEmissions = sortedEmissions.last.toDouble();

    print("max emissions is $maxEmissions");
    print("min emissions is $minEmissions");

    if (currentMaxEmissions < maxEmissions) {
      currentMaxEmissions = maxEmissions;
    }

    if ((currentMinEmissions > minEmissions && maxEmissions != minEmissions) ||
        currentMinEmissions == 0) {
      currentMinEmissions = minEmissions;
    }

    print(
        "current max emissions is $currentMaxEmissions && currentminEmissions $currentMinEmissions");
  }

  calculateColour(minEmissions, maxEmissions, selectedRouteEmission) {
    double t = 0;
    print(
        "selectedRouteEmission is inside calculateColour $selectedRouteEmission");
    print("max emissions is inside calculateColour $maxEmissions");
    print("min emissions is inside calculateColour $minEmissions");
    print("Initial t value: $t");
    if (maxEmissions <= _minEmissionThreshold) {
      double tLimit = 0.3; // cannot be higher than this to avoid brown colours
      double tResult = ((selectedRouteEmission - minEmissions) /
              (maxEmissions - minEmissions)) *
          tLimit;
      t = tResult;
      print("t value in if block: $t");
    } else if (minEmissions >= _maxEmissionThreshold) {
      double lowerLimit = 0.0; // might need this value to adjust the colour
      double upperLimit = 0.8; // cannot be lower than this to avoid brown colours
      double range = upperLimit - lowerLimit;
      double proportion = ((selectedRouteEmission - minEmissions) /
          (maxEmissions - minEmissions));
      t = lowerLimit + proportion * range;
      print("t value in else if block: $t");
    } else {
      t = (selectedRouteEmission - minEmissions) /
          (maxEmissions - minEmissions);
      print("t value in else block: $t");
    }
    t = t.clamp(0.0, 1.0);
    print("Final t value after clamping: $t");
    return HSLColor.lerp(_endColour, _startColour, t)!.toColor();
  }

  ThemeData _buildTheme() {
    print("seed colour is $_seedColour");

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
