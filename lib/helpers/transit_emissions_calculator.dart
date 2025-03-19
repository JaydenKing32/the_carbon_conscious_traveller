import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/coordinates_state.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';

class TransitEmissionsCalculator {
  double getPublicFactor(String vehicleTypeString) {
    try {
      switch (vehicleTypeString) {
        case 'BUS':
          return BusType.averageLocalBus.value;
        case 'INTERCITY_BUS':
          return BusType.coach.value;
        case 'HEAVY_RAIL':
        case 'HIGH_SPEED_TRAIN':
        case 'LONG_DISTANCE_TRAIN':
          return RailType.nationalRail.value;
        case 'COMMUTER_TRAIN':
        case 'METRO_RAIL':
        case 'MONORAIL':
        case 'RAIL':
        case 'TRAM':
          return RailType.lightRailAndTram.value;
        case 'SUBWAY':
          return RailType.londonUnderground.value;
        case 'FERRY':
          return FerryType.footPassenger.value;
        case 'TROLLEYBUS':
          return trolleybusValue;
        case 'CABLE_CAR':
          return cableCarValue;
        default:
          return 0.0;
      }
    } catch (e) {
      return 0.0;
    }
  }

  List<double> calculateEmissions(BuildContext context) {
    var coordState = Provider.of<CoordinatesState>(context, listen: false);
    // Map over the route results and calculate the emissions for each leg
    return coordState.routeData.map((route) {
      var emissions = 0.0;
      for (var leg in route.legs!) {
        for (var step in leg.steps!) {
          var distance = step.distance?.value ?? 0;
          if (step.travelMode.toString() == 'TRANSIT') {
            emissions += (getPublicFactor((step.transit?.line?.vehicle?.type.toString() ?? ''))) * distance.round();
          }
        }
      }
      // Return the calculated emissions for each leg
      return emissions;
    }).toList(); // Collect all emissions into a list
  }

  List<double> calculateStepEmissions(List<dynamic> steps) {
    // Map over the steps in each leg and calculate the emissions for each step
    return steps.map((step) {
      var stepEmissions = 0.0;
      var distance = step.distance?.value ?? 0;
      if (step.travelMode.toString() == 'TRANSIT') {
        stepEmissions = (getPublicFactor((step.transit?.line?.vehicle?.type.toString() ?? ''))) * distance.round();
      }
      // Return the calculated emissions for each step
      return stepEmissions;
    }).toList(); // Collect all emissions into a list
  }
}
