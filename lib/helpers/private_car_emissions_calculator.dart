import 'dart:math';

import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';

class PrivateCarEmissionsCalculator {
  final PolylinesState polylinesState;
  final CarSize vehicleSize;
  final CarFuelType vehicleFuelType;
  double factor = 0.0;

   PrivateCarEmissionsCalculator.fromSettings({
    required this.polylinesState,
    required Settings settings,
  }) : vehicleSize = settings.selectedCarSize,
       vehicleFuelType = settings.selectedCarFuelType {
    calculateFactor();
  }
  
  PrivateCarEmissionsCalculator({
    required this.polylinesState,
    required this.vehicleSize,
    required this.vehicleFuelType,
  }) {
    calculateFactor();
  }

   void calculateFactor() {
    if (vehicleSize == CarSize.label || vehicleFuelType == CarFuelType.label) {
      factor = 0.0;
    } else {
      factor = carValuesMatrix[vehicleSize.index][vehicleFuelType.index];
    }
   }

  double calculateEmissions(int index, CarSize carSize, CarFuelType carFuelType) {
    if (factor == 0.0) {
      // Handle the case where factor is not set (i.e., label is selected)
      // You can choose to return 0.0 or throw an exception based on your requirements
      return 0.0;
    }

    if (index < 0 || index >= polylinesState.distances.length) {
      throw RangeError('Index out of range in calculateEmissions');
    }

    return polylinesState.distances[index] * factor;
  }

  double calculateMinEmission() {
    if (factor == 0.0) {
      return 0.0;
    }
    return polylinesState.distances.reduce(min) * factor;
  }

  double calculateMaxEmission() {
    if (factor == 0.0) {
      return 0.0;
    }
    return polylinesState.distances.reduce(max) * factor;
  }
}
