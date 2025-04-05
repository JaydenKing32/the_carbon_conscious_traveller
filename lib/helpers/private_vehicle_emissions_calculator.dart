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
    factor = routeBikeSize.value;
  }

  double calculateEmission(int index) {
    if (index < 0 || index >= polylinesState.distances.length) {
      return 0.0;
    }
    final distance = polylinesState.distances[index];
    return distance * factor;
  }

  double calculateMinEmission() {
    if (polylinesState.distances.isEmpty) {
      return 0.0;
    }
    final minDist = polylinesState.distances.reduce(min);
    return minDist * factor;
  }

  double calculateMaxEmission() {
    if (polylinesState.distances.isEmpty) {
      return 0.0;
    }
    final maxDist = polylinesState.distances.reduce(max);
    return maxDist * factor;
  }
}
