import 'dart:math';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';

class PrivateVehicleEmissionsCalculator {
  final PolylinesState polylinesState;
  final MotorcycleSize vehicleSize;

  PrivateVehicleEmissionsCalculator({
    required this.polylinesState,
    required this.vehicleSize,
  });

   double calculateEmission(int index) {
    if (index < 0 || index >= polylinesState.distances.length) {
      return 0.0;
    }
    return polylinesState.distances[index] * vehicleSize.value;
  }
  double calculateMinEmission() {
    return polylinesState.distances.reduce(min) * vehicleSize.value;
  }

  double calculateMaxEmission() {
    return polylinesState.distances.reduce(max) * vehicleSize.value;
  }
}
