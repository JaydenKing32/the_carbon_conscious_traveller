import 'dart:math';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';

class PrivateCarEmissionsCalculator {
  final PolylinesState polylinesState;
  final Settings settings;

  /// The car chosen for *this route*, e.g. from your UI.
  final CarSize routeCarSize;
  final CarFuelType routeCarFuel;

  double factor = 0.0;

  PrivateCarEmissionsCalculator({
    required this.polylinesState,
    required this.settings,
    required this.routeCarSize,
    required this.routeCarFuel,
  }) {
    if (routeCarSize == CarSize.label || routeCarFuel == CarFuelType.label) {
      factor = 0.0;
    } else {
      factor = carValuesMatrix[routeCarSize.index][routeCarFuel.index];
    }
  }

  double calculateEmissions(int index, CarSize carSize, CarFuelType carFuelType) {
    if (index < 0 || index >= polylinesState.distances.length) {
      throw RangeError('Index out of range in calculateEmissions');
    }
    return factor * polylinesState.distances[index];
  }

  double calculateMinEmission() {
    if (factor == 0.0 || polylinesState.distances.isEmpty) return 0.0;
    final minDist = polylinesState.distances.reduce(min);
    return minDist * factor;
  }

  double calculateMaxEmission() {
    if (factor == 0.0 || polylinesState.distances.isEmpty) return 0.0;
    final maxDist = polylinesState.distances.reduce(max);
    return maxDist * factor;
  }
}
