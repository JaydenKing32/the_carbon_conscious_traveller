// travel_mode_buttons.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/coloursync_state.dart';
import 'package:the_carbon_conscious_traveller/state/coordinates_state.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_car_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_motorcycle_state.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
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
  List<bool> isSelected = <bool>[true, false, false, false];
  int lastSelectedIndex = 0;

  final List<({IconData icon, String mode})> transportModes = [
    (icon: Icons.directions_car_outlined, mode: 'driving'),
    (icon: Icons.sports_motorsports_outlined, mode: 'motorcycling'),
    (icon: Icons.train_outlined, mode: 'transit'),
    (icon: Icons.airplanemode_active_outlined, mode: 'flying'),
  ];

  void toggleInactiveButtons() {
    setState(() {
      for (int i = 0; i < isSelected.length; i++) {
        if (i != lastSelectedIndex) {
          isSelected[i] =
              !isSelected[i]; // Toggle visibility of inactive buttons
        }
      }
    });
  }

  void toggleSelection(int index) {
    String selectedMode = transportModes[index].mode;

    if (selectedMode == 'flying') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Flying(),
        ),
      );
      return;
    }

    setState(() {
      lastSelectedIndex = index; // Update the active button index
      for (int i = 0; i < isSelected.length; i++) {
        isSelected[i] = (i == index); // Only the selected button is active
      }

      // Call the polylineState and coordinatesState logic
      final polylineState = context.read<PolylinesState>();
      final coordinatesState = context.read<CoordinatesState>();
      polylineState.transportMode = selectedMode;

      if (coordinatesState.coordinates.isNotEmpty) {
        polylineState.setActiveRoute(polylineState.getActiveRoute());
      }

      // Clear existing colours for that mode (if not already calculated)
      // This is to give visual feedback that that mode has not been calculated yet
      final theme = context.read<ThemeState>();

      if (selectedMode == 'motorcycling' && theme.motoColourList.isEmpty) {
        polylineState.updateColours([]);
        polylineState.getPolyline(coordinatesState.coordinates);
      } else if (selectedMode == 'transit' && theme.transitColourList.isEmpty) {
        polylineState.updateColours([]);
      } else if (selectedMode == 'driving' && theme.carColourList.isEmpty) {
        polylineState.updateColours([]);
        polylineState.getPolyline(coordinatesState.coordinates);
      }
    });
  }

  String getCurrentMinMaxEmissions(
    String mode,
    PrivateMotorcycleState motorcycleState,
    PrivateCarState carState,
    TransitState transitState,
  ) {
    String formatNumber(int number) {
      if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(2)}kg';
      } else {
        return '${number.round()}g';
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
        return '';
    }
  }

  void resetSelection() {
    setState(() {
      for (int i = 0; i < isSelected.length; i++) {
        isSelected[i] = false;
      }
    });
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

    // fire immediately if already ready
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
      return Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.24, right: 16),
        child: Stack(
          alignment: Alignment.topRight,
          clipBehavior: Clip.none, // Allow overflow
          children: [
            // Inactive buttons (always behind)
            ...List.generate(4, (index) {
              // Calculate button position
              double calculatedTop = (index < lastSelectedIndex)
                  ? (index + 1) * 60.0
                  : (index) * 60.0;

              return AnimatedPositioned(
                duration: Duration(
                    milliseconds: 500 + (index * 100)), // Staggered delay
                curve: Curves.easeInOutCubic, // Smoother slide
                top: isSelected[index] ? calculatedTop : (calculatedTop - 60),
                right: 0,
                child: IgnorePointer(
                  ignoring:
                      !isSelected[index], // Only interactable when visible
                  child: AnimatedOpacity(
                    duration: Duration(
                        milliseconds: 250 + (index * 50)), // Staggered fade
                    opacity: isSelected[index]
                        ? 1.0
                        : 0.0, // Only visible when active
                    child: GestureDetector(
                      onTap: () {
                        toggleSelection(index);
                        toggleInactiveButtons();
                        resetSelection();
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 2.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            transportModes[index].icon,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Active button (always on top, drawn separately)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    // Toggle visibility of other buttons
                    toggleInactiveButtons();
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      transportModes[lastSelectedIndex].icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
