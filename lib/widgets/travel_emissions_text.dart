// travel_mode_buttons.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/coordinates_state.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_car_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_motorcycle_state.dart';
import 'package:the_carbon_conscious_traveller/state/theme_state.dart';
import 'package:the_carbon_conscious_traveller/state/transit_state.dart'; // Ensure correct import path

class TravelEmissionsText extends StatefulWidget {
  const TravelEmissionsText({super.key});

  @override
  State<TravelEmissionsText> createState() =>
      _TravelEmissionsText();
}

final ValueNotifier<bool> coloursReadyNotifier = ValueNotifier(false);

class _TravelEmissionsText extends State<TravelEmissionsText> {


  String getCurrentMinMaxEmissions(
    String mode,
    PrivateMotorcycleState motorcycleState,
    PrivateCarState carState,
    TransitState transitState,
  ) {
    String formatNumber(int number) {
      if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(2)} kg';
      } else {
        return '${number.round()} g';
      }
    }

    String getEmissions(int maxEmissionValue, int minEmissionValue) {
      String currentMaxEmissions = formatNumber(maxEmissionValue);
      String currentMinEmissions = formatNumber(minEmissionValue);
      if (maxEmissionValue == 0) {
        return '';
      } else if (maxEmissionValue == minEmissionValue) {
        return currentMaxEmissions;
      }
      return '$currentMinEmissions - $currentMaxEmissions';
    }

    const String motorcycling = 'motorcycling';
    const String driving = 'driving';
    const String transit = 'transit';

    switch (mode) {
      case motorcycling:
        if (motorcycleState.emissions.isEmpty) {
          return '';
        }
        return getEmissions(
          motorcycleState.maxEmissionValue,
          motorcycleState.minEmissionValue,
        );
      case driving:
        if (carState.emissions.isEmpty) {
          return '';
        }
        return getEmissions(
          carState.maxEmissionValue,
          carState.minEmissionValue,
        );
      case transit:
        if (transitState.emissions.isEmpty) {
          return '';
        }
        return getEmissions(
          transitState.maxEmissionValue,
          transitState.minEmissionValue,
        );
      default:
        return ''; // Handle 'flying' or other modes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer6<CoordinatesState, PrivateMotorcycleState, PrivateCarState,
        TransitState, PolylinesState, ThemeState>(
      builder: (BuildContext context,
          CoordinatesState coordinatesState,
          PrivateMotorcycleState motorcycleState,
          PrivateCarState carState,
          TransitState transitState,
          PolylinesState polylineState,
          ThemeState theme,
          child) {
        // Get emissions for each mode
        String drivingEmission = getCurrentMinMaxEmissions(
          'driving',
          motorcycleState,
          carState,
          transitState,
        );

        String motorcyclingEmission = getCurrentMinMaxEmissions(
          'motorcycling',
          motorcycleState,
          carState,
          transitState,
        );

        String transitEmission = getCurrentMinMaxEmissions(
          'transit',
          motorcycleState,
          carState,
          transitState,
        );

        // String flyingEmission = ''; // If you don't handle flying emissions

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (drivingEmission.isNotEmpty)
                  Row(children: [
                   const Icon(
                      Icons.directions_car_outlined,
                      size: 20.0,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      drivingEmission,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14
                      ),
                    ),
                    const SizedBox(width: 12),
                  ]),
                  if (motorcyclingEmission.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.sports_motorsports_outlined,
                      size: 20.0,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      motorcyclingEmission,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                   const SizedBox(width: 12),
                  ],
                ),
                if (transitEmission.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.train_outlined,
                      size: 20.0,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      transitEmission,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
