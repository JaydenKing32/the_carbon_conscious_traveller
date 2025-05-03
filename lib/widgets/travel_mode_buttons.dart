// travel_mode_buttons.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/coloursync_state.dart';
import 'package:the_carbon_conscious_traveller/state/coordinates_state.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_car_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_motorcycle_state.dart';
import 'package:the_carbon_conscious_traveller/state/theme_state.dart';
import 'package:the_carbon_conscious_traveller/state/transit_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/travel_mode_flying.dart'; // Ensure correct import path

class TravelModeButtons extends StatefulWidget {
  const TravelModeButtons({super.key});

  @override
  State<TravelModeButtons> createState() => _TravelModeButtonsState();
}



final ValueNotifier<bool> coloursReadyNotifier = ValueNotifier(false);

const String motorcycling = 'motorcycling';
const String driving = 'driving';
const String transit = 'transit';
const String flying = 'flying'; // Flying mode

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
void initState() {
  super.initState();

  final sync = context.read<ColourSyncState>();

  sync.addListener(() {
    if (sync.coloursReady) {
      _handlePolyline();
      sync.setColoursReady(false);
    }
  });

  // 👇 fire immediately if already ready
  if (sync.coloursReady) {
    _handlePolyline();
    sync.setColoursReady(false);
  }
}

void _handlePolyline() {
  final polylineState = context.read<PolylinesState>();
  final coordinates = context.read<CoordinatesState>().coordinates;

  if (coordinates.isNotEmpty) {
    polylineState.getPolyline(coordinates);
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
                    String selectedMode = transportModes[index].mode;

                    if (selectedMode == flying) {
                      // For 'flying' mode, navigate to Flying widget
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Flying(),
                        ),
                      );
                      return; // Exit the onPressed handler
                    }

                    setState(() {
                      // The button that is tapped is set to true, and the others to false
                      for (int i = 0; i < _selectedModes.length; i++) {
                        _selectedModes[i] = i == index;
                      }
                    });

                      //polylineState.updateColours(theme.seedColourList);
                    // polylineState.setPolyColours(theme.seedColourList);
                    polylineState.transportMode = selectedMode;

                    // If coordinates are set, fetch new polyline
                    // this is called every time the button is pressed IF we have routes
                    if (coordinatesState.coordinates.isNotEmpty) {
                      if(polylineState.mode == 'motorcycling') {
                         print("seed colour list is in moto mode buttons ${theme.motoColourList.length}");
                        //polylineState.updateColours(theme.motoColourList);
                      // } else if(polylineState.mode == 'driving') {
                      //   polylineState.setPolyColours(theme.seedColourList);
                      } else if(polylineState.mode == 'transit') {
                        print("seed colour list is in transit mode buttons ${theme.transitColourList.length}");
                        //polylineState.updateColours(theme.transitColourList);
                      }
                      polylineState.setActiveRoute(polylineState.getActiveRoute());
                     // context.read<ColourSyncState>().addListener(() {
                      // if (context.read<ColourSyncState>().coloursReady) {
                      //     polylineState.getPolyline(coordinatesState.coordinates);
                      // }
// });

                    }
                  },
                  renderBorder: false,
                  highlightColor: theme.seedColour.withAlpha(50),
                  selectedColor: theme.seedColour,
                  color: Colors.grey[600],
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
