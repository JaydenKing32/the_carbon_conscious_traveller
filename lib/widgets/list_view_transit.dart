import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/helpers/transit_emissions_calculator.dart';
import 'package:the_carbon_conscious_traveller/helpers/verify_service.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';
import 'package:the_carbon_conscious_traveller/state/coloursync_state.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/state/theme_state.dart';
import 'package:the_carbon_conscious_traveller/state/transit_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/transit_steps.dart';
import 'package:the_carbon_conscious_traveller/widgets/travel_mode_buttons.dart';
import 'package:the_carbon_conscious_traveller/widgets/tree_icons.dart';
import 'package:auto_size_text/auto_size_text.dart';

class TransitListView extends StatefulWidget {
  const TransitListView({super.key, required this.polylinesState, required this.snapshot, required this.emissions, required this.settings});

  final dynamic snapshot;
  final List<double> emissions;
  final Settings settings;
  final PolylinesState polylinesState;

  @override
  State<TransitListView> createState() => _TransitListViewState();
}

class _TransitListViewState extends State<TransitListView> {
  final Set<int> _savedTripIds = {}; // Store trip IDs from DB
  final Map<int, int> _indexToTripId = {}; // Maps UI index -> DB trip ID
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

  Future<void> _loadSavedTrips() async {
    List<Trip> trips = await TripDatabase.instance.getAllTrips();
    setState(() {
      _savedTripIds.clear();
      _indexToTripId.clear();
      for (var trip in trips) {
        _savedTripIds.add(trip.id!);
      }
    });
  }

  int getMaxDistance(List<DirectionsRoute> routes) {
    return routes.map((DirectionsRoute route) => route.legs?.fold(0, (a, leg) => a + leg.steps!.fold(0, (b, step) => b + (step.distance!.value!).toInt()))).reduce((a, b) => a! > b! ? a : b)!;
  }

  Future<void> _saveTrip(int index) async {
    int maxEmission = widget.emissions.isNotEmpty ? widget.emissions.map((e) => e.toInt()).reduce(max) : 0;

    double selectedEmission = widget.emissions[index];
    double reduction = max(0, maxEmission - selectedEmission);
    List<Leg>? legs = widget.snapshot.data![index].legs;
    GeoCoord? start = legs?.first.steps?.first.startLocation;
    GeoCoord? end = legs?.last.steps?.last.endLocation;

    double configuredFactor = -1;
    if (widget.settings.useCarForCalculations && !widget.settings.useMotorcycleInsteadOfCar) {
      configuredFactor = carValuesMatrix[widget.settings.selectedCarSize.index][widget.settings.selectedCarFuelType.index];
    } else if (widget.settings.useMotorcycleForCalculations && (widget.settings.useMotorcycleInsteadOfCar || !widget.settings.useCarForCalculations)) {
      configuredFactor = widget.settings.selectedMotorcycleSize.value;
    }

    if (configuredFactor != -1) {
      int maxDistance = getMaxDistance(widget.snapshot.data);
      double maxConfiguredEmission = configuredFactor * maxDistance;
      reduction = max(0, maxConfiguredEmission - selectedEmission);
    }

    final transitType = legs?.fold(
        "", (a, leg) => "$a!${leg.steps?.fold("", (b, step) => "$b!${step.travelMode.toString() == "TRANSIT" ? step.transit?.line?.vehicle?.type.toString() : step.travelMode.toString()}")}");

    final trip = Trip(
      date: DateTime.now().toIso8601String(),
      origin: legs?.first.startAddress ?? "Unknown",
      origLat: start?.latitude ?? 0.0,
      origLng: start?.longitude ?? 0.0,
      destination: legs?.last.endAddress ?? "Unknown",
      destLat: end?.latitude ?? 0.0,
      destLng: end?.longitude ?? 0.0,
      distance: legs?.map((l) => l.distance?.value?.toInt()).reduce((a, b) => (a ?? 0) + (b ?? 0)) ?? 0,
      emissions: widget.emissions[index],
      mode: "Transit",
      reduction: reduction,
      complete: false,
      model: transitType ?? "Unknown",
    );

    int id = await TripDatabase.instance.insertTrip(trip);
    trip.id = id;
    setState(() {
      _savedTripIds.add(id);
      _indexToTripId[index] = id;
    });

    if (widget.settings.enableGeolocationVerification) {
      List<LatLng> coords = widget.polylinesState.routeCoordinates[index];
      VerifyService.update(coords, id);
    }
  }

  Future<void> _deleteTrip(int index) async {
    int? tripId = _indexToTripId[index];
    if (tripId != null && _savedTripIds.contains(tripId)) {
      await TripDatabase.instance.deleteTrip(tripId);

      setState(() {
        _savedTripIds.remove(tripId);
        _indexToTripId.remove(index);
      });
    }
  }

  String formatNumber(double number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)} kg';
    } else {
      return '${number.round()} g';
    }
  }

  Future<void> _toggleTripCompletion(int index) async {
    int? tripId = _indexToTripId[index];
    if (tripId != null && _savedTripIds.contains(tripId)) {
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
    int? tripId = _indexToTripId[index];
    Trip? trip = await TripDatabase.instance.getTripById(tripId!);

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

  @override
  Widget build(BuildContext context) {
    TransitEmissionsCalculator? transitEmissionsCalculator = TransitEmissionsCalculator();
    TransitState transitState = Provider.of<TransitState>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      transitState.saveEmissions(widget.emissions.map((e) => e.toInt()).toList());
      transitState.updateMinEmission(widget.emissions.reduce(min).round());
      transitState.updateMaxEmission(widget.emissions.reduce(max).round());
    });

    // We need to create focus nodes to handle the focus of the list items
    // This way we handle colour updates based on the selected route
    if (focusNodes.length != widget.emissions.length) {
      // Clean up old nodes
      for (final node in focusNodes) {
        node.dispose();
      }
      // Recreate new nodes
      focusNodes = List.generate(widget.emissions.length, (_) => FocusNode());
    }
    return Consumer3<PolylinesState, Settings, ThemeState>(
      builder: (context, polylinesState, settings, theme, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Column(
          children: [
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: widget.snapshot.data!.length,
              itemBuilder: (context, index) {
                List<dynamic> legs = widget.snapshot.data![index].legs;
                List<dynamic> steps = widget.snapshot.data![index].legs?.first.steps;
                List<double> stepEmissions = transitEmissionsCalculator.calculateStepEmissions(steps);

                int selectedIndex = polylinesState.transitActiveRouteIndex;
                int? sIndex = _indexToTripId[index];
                bool isCompleted = sIndex != null ? _tripCompletionStatus[sIndex] ?? false : false;

                transitState.getTreeIcons(index, context);
                double carFactor = carValuesMatrix[settings.selectedCarSize.index][settings.selectedCarFuelType.index];
                double motorcycleFactor = settings.selectedMotorcycleSize.value;
                int maxDistance = getMaxDistance(widget.snapshot.data);
                transitState.updateMaxConfiguredEmissions(driving, carFactor * maxDistance);
                transitState.updateMaxConfiguredEmissions(motorcycling, motorcycleFactor * maxDistance);

                // Determine the border color using the currently selected route
                // If the theme is too light, use brown. Otherwise, use the seed color
                //Default to transparent if not selected
                Color borderColour = (selectedIndex == index) ? (theme.isTooLight ? Colors.brown : theme.seedColour) : Colors.transparent;

                // If the polyline was tapped, update the theme color
                if (polylinesState.polyTapped) {
                  // Bring back the focus to the selected route in the list view
                  // if needed
                  if (focusNodes.length != transitState.emissions.length) {
                    // Clean up old nodes
                    for (final node in focusNodes) {
                      node.dispose();
                    }
                    // Recreate new nodes
                    focusNodes = List.generate(transitState.emissions.length, (_) => FocusNode());
                  }
                  theme.setThemeColour(polylinesState.transitActiveRouteIndex);
                  polylinesState.polyTapped = false;
                }

                return InkWell(
                  focusNode: focusNodes[index],
                  onFocusChange: (focused) {
                    if (focused) {
                      // theme.seedColourList.clear(); // this causes an invisible error. Do not use
                      for (int i = 0; i < widget.emissions.length; i++) {
                        theme.calculateColour(
                          transitState.minEmissionValue,
                          transitState.maxEmissionValue,
                          transitState.emissions[i],
                          i,
                          transitState.emissions.length,
                          polylinesState.mode,
                        );
                      }
                      polylinesState.updateColours(theme.transitColourList);
                      theme.setThemeColour(polylinesState.transitActiveRouteIndex);
                      context.read<ColourSyncState>().setColoursReady(true);
                    }
                  },
                  autofocus: index == selectedIndex,
                  onTap: () {
                    //FocusScope.of(context).requestFocus(focusNodes[index]);
                    setState(() {
                      polylinesState.setActiveRoute(index);
                    });
                    theme.setThemeColour(polylinesState.transitActiveRouteIndex);
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TransitSteps(steps: steps, stepEmissions: stepEmissions),
                                Padding(
                                  padding: EdgeInsets.only(top: screenHeight * 0.01),
                                  child: AutoSizeText(
                                    legs.first.departureTime?.text == null ? "" : "${legs.first.departureTime?.text} - ${legs.first.arrivalTime?.text}",
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    minFontSize: 8,
                                    maxFontSize: 10,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end, // Align text to the right
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end, // Aligns emissions text + icon
                                  children: [
                                    AutoSizeText(
                                      formatNumber(widget.emissions[index]),
                                      style: Theme.of(context).textTheme.bodyLarge,
                                      minFontSize: 8,
                                      maxFontSize: 14, // Allows text to scale up/down
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(width: MediaQuery.of(context).size.width * 0.005),
                                    Image.asset(
                                      'assets/icons/co2e.png',
                                      width: MediaQuery.of(context).size.width * 0.06, // Adjust dynamically
                                      height: MediaQuery.of(context).size.height * 0.03,
                                    ),
                                  ],
                                ),
                                SizedBox(height: MediaQuery.of(context).size.height * 0.002),
                                AutoSizeText(
                                  "${legs.first.distance?.text ?? ''}",
                                  style: Theme.of(context).textTheme.bodySmall,
                                  minFontSize: 8,
                                  maxFontSize: 12,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                AutoSizeText(
                                  "${legs.first.duration?.text ?? ''}",
                                  style: Theme.of(context).textTheme.bodySmall,
                                  minFontSize: 8,
                                  maxFontSize: 12,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                                TreeIcons(
                                  treeIconName: transitState.treeIcons,
                                  settings: settings,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _savedTripIds.contains(_indexToTripId[index] ?? -1) ? Icons.remove_circle_outline : Icons.add_circle_outline,
                                color: Colors.green,
                                size: screenWidth * 0.07, // Scaled size
                              ),
                              onPressed: () {
                                if (_savedTripIds.contains(_indexToTripId[index] ?? -1)) {
                                  _deleteTrip(index);
                                } else {
                                  _saveTrip(index);
                                }
                              },
                              tooltip: _savedTripIds.contains(_indexToTripId[index] ?? -1) ? 'Delete Trip' : 'Save Trip',
                            ),
                            IconButton(
                              icon: Icon(
                                isCompleted ? Icons.check_circle : Icons.cancel_outlined,
                                color: isCompleted ? Colors.green : Colors.black,
                                size: screenWidth * 0.07, // Scaled size
                              ),
                              onPressed: settings.enableGeolocationVerification ? () => _attemptGeolocCompletion(index) : () => _toggleTripCompletion(index),
                              tooltip: isCompleted ? 'Mark Incomplete' : 'Mark Complete',
                            ),
                            SizedBox(height: screenHeight * 0.005),
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
