import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/helpers/verify_service.dart';
import 'package:the_carbon_conscious_traveller/state/coloursync_state.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';
import 'package:the_carbon_conscious_traveller/state/private_motorcycle_state.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/state/theme_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/tree_icons.dart';

class MotorcycleListView extends StatefulWidget {
  const MotorcycleListView({super.key, required this.vehicleState, required this.polylinesState, required this.icon, required this.settings});

  final PrivateMotorcycleState vehicleState; // Specific type instead of dynamic
  final PolylinesState polylinesState;
  final IconData icon;
  final Settings settings;

  @override
  State<MotorcycleListView> createState() => _MotorcycleListViewState();
}

class _MotorcycleListViewState extends State<MotorcycleListView> {
  final Set<int> _savedTripIds = {};
  final Map<String, int> _routeToTripId = {}; // Map route summary to trip ID
  final Map<int, bool> _tripCompletionStatus = {};

  List<FocusNode> focusNodes = [];

  @override
  void initState() {
    super.initState();
    _loadSavedTrips();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    final indexToFocus = context.read<PolylinesState>().activeRouteIndex;
    FocusScope.of(context).requestFocus(focusNodes[indexToFocus]);
  });
  }

  @override
    void dispose() {
      // Clean up all the focus nodes to avoid memory leaks
      for (final node in focusNodes) {
        node.dispose();
      }
      focusNodes.clear();
      super.dispose();
    }

  /// Loads saved trips from the database and maps them to their respective routes.
  Future<void> _loadSavedTrips() async {
    List<Trip> trips = await TripDatabase.instance.getAllTrips();
    setState(() {
      _savedTripIds.clear();
      _routeToTripId.clear();
      for (var trip in trips) {
        _savedTripIds.add(trip.id!);
      }
    });
  }

  /// Saves a trip to the database and updates the local state.
  Future<void> _saveTrip(int index) async {
    // Validate index to prevent RangeError
    if (!_isValidIndex(index)) {
      return;
    }

    String route = widget.polylinesState.routeSummary[index];
    // Check if a trip for this route already exists
    if (_routeToTripId.containsKey(route)) {
      // Trip already exists, do not save again
      return;
    }

    int maxEmission = widget.vehicleState.emissions.isNotEmpty ? widget.vehicleState.emissions.map((e) => e.toInt()).reduce(max) : 0;
    double selectedEmission = widget.vehicleState.getEmission(index).toDouble();
    double reduction = max(0, maxEmission - selectedEmission);

    double configuredFactor = -1;
    if (widget.settings.useCarForCalculations && !widget.settings.useMotorcycleInsteadOfCar) {
      configuredFactor = carValuesMatrix[widget.settings.selectedCarSize.index][widget.settings.selectedCarFuelType.index];
    } else if (widget.settings.useMotorcycleForCalculations && (widget.settings.useMotorcycleInsteadOfCar || !widget.settings.useCarForCalculations)) {
      configuredFactor = widget.settings.selectedMotorcycleSize.value;
    }

    if (configuredFactor != -1) {
      double maxConfiguredEmission = configuredFactor * widget.polylinesState.distances.reduce(max);
      reduction = max(0, maxConfiguredEmission - selectedEmission);
    }

    String motoModel = widget.vehicleState.selectedValue.toString().split('.').last;
    if (motoModel.isNotEmpty) {
      motoModel = motoModel[0].toUpperCase() + motoModel.substring(1);
    }
    List<Leg>? legs = widget.polylinesState.routes?[index].legs;
    GeoCoord? start = legs?.first.steps?.first.startLocation;
    GeoCoord? end = legs?.last.steps?.last.endLocation;

    final trip = Trip(
      date: DateTime.now().toIso8601String(),
      origin: legs?.first.startAddress ?? "Unknown",
      origLat: start?.latitude ?? 0.0,
      origLng: start?.longitude ?? 0.0,
      destination: legs?.last.endAddress ?? "Unknown",
      destLat: end?.latitude ?? 0.0,
      destLng: end?.longitude ?? 0.0,
      distance: legs?.map((l) => l.distance?.value?.toInt()).reduce((a, b) => (a ?? 0) + (b ?? 0)) ?? 0,
      emissions: widget.vehicleState.getEmission(index).toDouble(),
      mode: "Motorcycle",
      reduction: reduction,
      complete: false,
      model: motoModel,
    );

    int id = await TripDatabase.instance.insertTrip(trip);
    trip.id = id;
    setState(() {
      _savedTripIds.add(id);
      _routeToTripId[route] = id;
    });

    if (widget.settings.verifyLocation) {
      List<LatLng> coords = widget.polylinesState.routeCoordinates[index];
      VerifyService.update(coords, id);
    }
  }

  /// Deletes a trip from the database and updates the local state.
  Future<void> _deleteTrip(int index) async {
    if (!_isValidIndex(index)) {
      return;
    }

    String route = widget.polylinesState.routeSummary[index];
    if (!_routeToTripId.containsKey(route)) {
      return;
    }

    int tripId = _routeToTripId[route]!;
    if (_savedTripIds.contains(tripId)) {
      await TripDatabase.instance.deleteTrip(tripId);
      setState(() {
        _savedTripIds.remove(tripId);
        _routeToTripId.remove(route);
        _tripCompletionStatus.remove(tripId);
      });
    }
  }

  /// Toggles the completion status of a trip.
  Future<void> _toggleTripCompletion(int index) async {
    if (!_isValidIndex(index)) {
      return;
    }

    String route = widget.polylinesState.routeSummary[index];
    if (!_routeToTripId.containsKey(route)) {
      return;
    }

    int tripId = _routeToTripId[route]!;
    if (_savedTripIds.contains(tripId)) {
      Trip? trip = await TripDatabase.instance.getTripById(tripId);
      if (trip != null) {
        bool newStatus = !trip.complete;
        await TripDatabase.instance.updateTripCompletion(tripId, newStatus);
        setState(() {
          _tripCompletionStatus[tripId] = newStatus;
        });
      }
    }
  }

  Future<void> _attemptGeolocCompletion(int index) async {
    String route = widget.polylinesState.routeSummary[index];
    int tripId = _routeToTripId[route]!;
    Trip? trip = await TripDatabase.instance.getTripById(tripId);

    if (trip!.complete) return;

    final position = await Geolocator.getCurrentPosition();

    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      trip.destLat,
      trip.destLng,
    );

    const double thresholdMeters = 50;
    if (distanceInMeters <= thresholdMeters) {
      if (trip.id != null) {
        await TripDatabase.instance.updateTripCompletion(trip.id!, true);
        setState(() {
          _tripCompletionStatus[trip.id!] = true;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You have not reached the destination."),
          ),
        );
      }
    }
  }

  /// Formats the emission value for display.
  String formatEmission(int emission) {
    if (emission >= 1000) {
      return "${(emission / 1000).toStringAsFixed(2)} kg";
    } else {
      return "$emission g";
    }
  }

  /// Validates whether the provided index is within the bounds of all relevant lists.
  bool _isValidIndex(int index) {
    return index >= 0 &&
        index < widget.polylinesState.routeSummary.length &&
        index < widget.polylinesState.distanceTexts.length &&
        index < widget.polylinesState.durationTexts.length &&
        index < widget.vehicleState.emissions.length;
  }



final ValueNotifier<bool> coloursReadyNotifier = ValueNotifier(false);




  @override
  Widget build(BuildContext context) {

    // We need to create focus nodes to handle the focus of the list items
    // This way we handle colour updates based on the selected route
    if (focusNodes.length != widget.vehicleState.emissions.length) {
    // Clean up old nodes
    for (final node in focusNodes) {
      node.dispose();
    }
    // Recreate new nodes
    focusNodes = List.generate(widget.vehicleState.emissions.length, (_) => FocusNode());
  }
    return Consumer3<PolylinesState, Settings, ThemeState>(
      builder: (context, polylinesState, settings, theme, child) {
        // Check if data is available
        if (polylinesState.resultForPrivateVehicle.isEmpty) {
          return const Center(
            child: Text("No motorcycle routes available."),
          );
        }

        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: widget.polylinesState.resultForPrivateVehicle.length,
              itemBuilder: (BuildContext context, int index) {
                // Validate index to prevent RangeError
                if (!_isValidIndex(index)) {
                  _loadSavedTrips();
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                      ],
                    ),
                  ); // Or display a placeholder widget
                }

                // Fetch the trip ID and completion status for the current route
                String route = widget.polylinesState.routeSummary[index];
                int? tripId = _routeToTripId[route];
                bool isCompleted = tripId != null ? _tripCompletionStatus[tripId] ?? false : false;
                int selectedIndex = polylinesState.motorcycleActiveRouteIndex;

                // Determine the border color using the currently selected route
                // If the theme is too light, use brown. Otherwise, use the seed color
                //Default to transparent if not selected
                Color borderColour = (selectedIndex == index)
                    ? (theme.isTooLight ? Colors.brown : theme.seedColour)
                    : Colors.transparent;

                // Set the icon color based on the currently selected route
                // If the theme is too light, use brown. Otherwise, use the seed color
                // Default to black if not selected
                Color iconColor = (selectedIndex == index)
                    ? (theme.isTooLight ? Colors.brown : theme.seedColour)
                    : Colors.black;

                // If the polyline was tapped, update the theme color
                if (polylinesState.polyTapped) {
                  // Bring back the focus to the selected route in the list view
                  // if needed
                  if (focusNodes.length != widget.vehicleState.emissions.length) {
                    // Clean up old nodes
                    for (final node in focusNodes) {
                      node.dispose();
                    }
                    // Recreate new nodes
                    focusNodes = List.generate(widget.vehicleState.emissions.length, (_) => FocusNode());
                  }
                  theme.setThemeColour(polylinesState.motorcycleActiveRouteIndex);
                  polylinesState.polyTapped = false;
                }

                // Fetch tree icons based on emission
                widget.vehicleState.getTreeIcons(index, context);

                return InkWell(
                  focusNode: focusNodes[index],
                  onFocusChange: (focused) {
                    if (focused) {
                      // theme.seedColourList.clear();
                      for (int i = 0;
                          i < widget.vehicleState.emissions.length;
                          i++) {
                        theme.calculateColour(
                          widget.vehicleState.minEmissionValue,
                          widget.vehicleState.maxEmissionValue,
                          widget.vehicleState.emissions[i],
                          i,
                          widget.vehicleState.emissions.length,
                          polylinesState.mode,
                        );
                      }
                      polylinesState.updateColours(theme.motoColourList);
                      theme.setThemeColour(polylinesState.motorcycleActiveRouteIndex);
                      context.read<ColourSyncState>().setColoursReady(true);
                    }
                  },
                  //autofocus: selectedIndex == index,
                  onTap: () {
                   // FocusScope.of(context).requestFocus(focusNodes[index]);
                    setState(() {
                      polylinesState.setActiveRoute(index);
                    });
                    theme.setThemeColour(polylinesState.motorcycleActiveRouteIndex);
                    //context.read<ColourSyncState>().setColoursReady(true);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: borderColour,
                          width: 5.0,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.only(right: 10),
                                child: Icon(
                                  widget.icon,
                                  color: iconColor,
                                  size: 30,
                                ),
                              ),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    'via ${widget.polylinesState.routeSummary[index]}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: formatEmission(widget.vehicleState.getEmission(index)),
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                          const WidgetSpan(
                                            alignment: PlaceholderAlignment.middle,
                                            child: SizedBox(width: 4),
                                          ),
                                          WidgetSpan(
                                            child: Image.asset(
                                              'assets/icons/co2e.png',
                                              width: 20,
                                              height: 20,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.error,
                                                  size: 20,
                                                  color: Colors.red,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: widget.polylinesState.distanceTexts[index].split(' ').first,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    TextSpan(
                                      text: ' km',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.polylinesState.durationTexts[index],
                                style: Theme.of(context).textTheme.bodySmall,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                              const SizedBox(height: 4),
                              TreeIcons(
                                treeIconName: widget.vehicleState.treeIcons,
                                settings: settings,
                              )
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _savedTripIds.contains(_routeToTripId[route] ?? -1) ? Icons.remove_circle_outline : Icons.add_circle_outline,
                                color: Colors.green,
                                size: 28,
                              ),
                              onPressed: () {
                                if (_savedTripIds.contains(_routeToTripId[route] ?? -1)) {
                                  _deleteTrip(index);
                                } else {
                                  _saveTrip(index);
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.cancel_outlined,
                                color:
                                    isCompleted ? Colors.green : Colors.black,
                                size: 28,
                              ),
                              onPressed: settings.verifyLocation
                                  // If geolocation is ON => attempt location-based completion
                                  ? () => _attemptGeolocCompletion(index)
                                  // Otherwise => old behaviour, just toggle completion
                                  : () => _toggleTripCompletion(index),
                            ),
                            const SizedBox(height: 5),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) => const Divider(
                thickness: 2,
              ),
            ),
          ],
        );
      },
    );
  }
}
