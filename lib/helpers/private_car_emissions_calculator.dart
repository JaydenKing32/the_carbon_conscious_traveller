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
    calculateFactor();
  }

  /// Build factor either as:
  /// - The normal “routeCar” factor, OR
  /// - That minus the user's “specified car” factor, if useCarForCalculations is true.
  void calculateFactor() {
       if (settings.useSpecifiedCar && !settings.useCarForCalculations) {
          final userCarSize = settings.selectedCarSize; 
           final userFuelType = settings.selectedCarFuelType;

            double userCarFactor = 0.0;
      if (userCarSize != CarSize.label && userFuelType != CarFuelType.label) {
        userCarFactor = carValuesMatrix[userCarSize.index][userFuelType.index];
      }
      factor = userCarFactor;
       } else{
    // 1) If routeCar is "Select", set factor=0
    if (routeCarSize == CarSize.label || routeCarFuel == CarFuelType.label) {
      factor = 0.0;
      return;
    }

    // 2) The "standard" factor from the matrix for this route's chosen car
    final standardFactor =
        carValuesMatrix[routeCarSize.index][routeCarFuel.index];

    // 3) If user wants “useCarForCalculations”, we subtract the user's specified car factor
    if (settings.useCarForCalculations) {
      final userCarSize = settings.selectedCarSize; 
      final userFuelType = settings.selectedCarFuelType;

      double userCarFactor = 0.0;
      if (userCarSize != CarSize.label && userFuelType != CarFuelType.label) {
        userCarFactor = carValuesMatrix[userCarSize.index][userFuelType.index];
      }

      // For instance: difference approach
      factor = standardFactor - userCarFactor > 0 ? standardFactor - userCarFactor : 0;
    } else {
      factor = standardFactor;
    }
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
