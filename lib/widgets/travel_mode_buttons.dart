// travel_mode_buttons.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/coordinates_state.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_car_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_motorcycle_state.dart';
import 'package:the_carbon_conscious_traveller/state/transit_state.dart';

class TravelModeButtons extends StatefulWidget {
  const TravelModeButtons({super.key});

  @override
  State<TravelModeButtons> createState() => _TravelModeButtonsState();
}

const String motorcycling = 'motorcycling';
const String driving = 'driving';
const String transit = 'transit';
const String flying = 'flying'; // If you have emissions for flying, else handle appropriately

class _TravelModeButtonsState extends State<TravelModeButtons> {
  final List<bool> _selectedModes = <bool>[true, false, false, false];

  final List<({IconData icon, String mode})> transportModes = [
    (icon: Icons.directions_car_outlined, mode: 'driving'),
    (icon: Icons.sports_motorsports_outlined, mode: 'motorcycling'),
    (icon: Icons.train_outlined, mode: 'transit'),
    (icon: Icons.airplanemode_active_outlined, mode: 'flying'),
  ];

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
        if (transitState.transitEmissions.isEmpty) {
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
    return Consumer5<CoordinatesState, PrivateMotorcycleState, PrivateCarState, TransitState, PolylinesState>(
      builder: (BuildContext context,
          CoordinatesState coordinatesState,
          PrivateMotorcycleState motorcycleState,
          PrivateCarState carState,
          TransitState transitState,
          PolylinesState polylineState,
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

        //String flyingEmission = ''; // If you don't handle flying emissions

        return Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          color: Colors.white,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ToggleButtons(
                  onPressed: (int index) {
                    setState(() {
                      // The button that is tapped is set to true, and the others to false
                      for (int i = 0; i < _selectedModes.length; i++) {
                        _selectedModes[i] = i == index;
                      }
                    });

                    polylineState.transportMode = transportModes[index].mode;

                    // If coordinates are set, fetch new polyline
                    if (coordinatesState.coordinates.isNotEmpty) {
                      polylineState.setActiveRoute(polylineState.getActiveRoute());
                      polylineState.getPolyline(coordinatesState.coordinates);
                    }
                  },
                  renderBorder: false,
                  highlightColor: Colors.green[400],
                  selectedColor: Colors.green[600],
                  color: Colors.grey[600],
                  splashColor: Colors.green[200],
                  fillColor: Colors.transparent,
                  constraints: const BoxConstraints(
                    minHeight: 40.0,
                    minWidth: 40.0,
                  ),
                  isSelected: _selectedModes,
                  children: transportModes
                      .map(
                        (travelMode) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Icon(
                                  travelMode.icon,
                                  size: 30.0,
                                ),
                              ),
                              if (travelMode.mode == 'motorcycling')
                                Text(
                                  motorcyclingEmission,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (travelMode.mode == 'driving')
                                Text(
                                  drivingEmission,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (travelMode.mode == 'transit')
                                Text(
                                  transitEmission,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (travelMode.mode == 'flying')
                                const Text(
                                  '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
