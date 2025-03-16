import 'dart:math';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';

class PrivateVehicleEmissionsCalculator {
  final PolylinesState polylinesState;
  final Settings settings;

  /// The "route motorcycle" chosen in the UI or state
  final MotorcycleSize routeBikeSize;

  double factor = 0.0;

  PrivateVehicleEmissionsCalculator({
    required this.polylinesState,
    required this.settings,
    required this.routeBikeSize,
  }) {
    calculateFactor();
  }

  void calculateFactor() {
    final double standardFactor = routeBikeSize.value;

    if (settings.useCarForCalculations && !settings.useSpecifiedCar) {
      final userCarSize = settings.selectedCarSize;
      final userFuelType = settings.selectedCarFuelType;

      double userCarFactor = 0.0;

      if (userCarSize != CarSize.label && userFuelType != CarFuelType.label) {
        userCarFactor = carValuesMatrix[userCarSize.index][userFuelType.index];
      }

      factor = (standardFactor - userCarFactor) > 0
          ? (standardFactor - userCarFactor)
          : 0;
    } else {
      factor = standardFactor;
    }
  }

  double calculateEmission(int index) {
    if (index < 0 || index >= polylinesState.distances.length) {
      return 0.0;
    }
    final distance = polylinesState.distances[index];
    return distance * factor;
  }

  double calculateMinEmission() {
    if (polylinesState.distances.isEmpty) return 0.0;
    final minDist = polylinesState.distances.reduce(min);
    return minDist * factor;
  }

  double calculateMaxEmission() {
    if (polylinesState.distances.isEmpty) return 0.0;
    final maxDist = polylinesState.distances.reduce(max);
    return maxDist * factor;
  }
}
