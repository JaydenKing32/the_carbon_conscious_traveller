import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/state/coloursync_state.dart';
import 'package:the_carbon_conscious_traveller/helpers/verify_service.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/state/theme_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/tree_icons.dart';

class CarListView extends StatefulWidget {
  const CarListView({super.key, required this.vehicleState, required this.polylinesState, required this.icon, required this.settings});

  final dynamic vehicleState;
  final PolylinesState polylinesState;
  final IconData icon;
  final Settings settings;

  @override
  State<CarListView> createState() => _CarListViewState();
}

class _CarListViewState extends State<CarListView> {
  final Set<int> _savedTripIds = {};
  final Map<int, int> _indexToTripId = {};
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

  Future<void> _saveTrip(int index) async {
    // Ensure the index is within the bounds of the lists
    if (index < 0 ||
        index >= widget.polylinesState.routeSummary.length ||
        index >= widget.polylinesState.distanceTexts.length ||
        index >= widget.polylinesState.durationTexts.length ||
        index >= widget.vehicleState.emissions.length) {
      return;
    }

    int maxEmission = widget.vehicleState.emissions.isNotEmpty ? widget.vehicleState.emissions.map((e) => e.toInt()).reduce((a, b) => a > b ? a : b) : 0;
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

    String carModel = "${widget.vehicleState.selectedSize?.toString().split('.').last} - ${widget.vehicleState.selectedFuelType?.toString().split('.').last}";
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
        mode: "Car",
        reduction: reduction,
        complete: false,
        model: carModel);

    int id = await TripDatabase.instance.insertTrip(trip);
    trip.id = id;
    setState(() {
      _savedTripIds.add(id);
      _indexToTripId[index] = id;
    });

    if (widget.settings.verifyLocation) {
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

  String formatEmission(int emission) {
    if (emission >= 1000) {
      return "${(emission / 1000).toStringAsFixed(2)} kg";
    } else {
      return "$emission g";
    }
  }

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
      focusNodes = List.generate(
          widget.vehicleState.emissions.length, (_) => FocusNode());
    }

    return Consumer3<PolylinesState, Settings, ThemeState>(
      builder: (context, polylinesState, settings, theme, child) {
        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: widget.polylinesState.resultForPrivateVehicle.length,
              itemBuilder: (BuildContext context, int index) {
                widget.vehicleState.getTreeIcons(index, context);
                if (index >= widget.vehicleState.emissions.length ||
                    index >= widget.polylinesState.routeSummary.length ||
                    index >= widget.polylinesState.distanceTexts.length ||
                    index >= widget.polylinesState.durationTexts.length) {
                  _loadSavedTrips();
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                      ],
                    ),
                  );
                }
                int selectedIndex;
                widget.vehicleState.getTreeIcons(index, context);

                int? tripId = _indexToTripId[index];
                bool isCompleted = tripId != null ? _tripCompletionStatus[tripId] ?? false : false;
                selectedIndex = polylinesState.carActiveRouteIndex;

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
                  theme.setThemeColour(polylinesState.carActiveRouteIndex);
                  polylinesState.polyTapped = false;
                }

                return InkWell(
                  focusNode: focusNodes[index],
                  onFocusChange: (focused) {
                    if (focused) {
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
                      polylinesState.updateColours(theme.carColourList);
                      theme.setThemeColour(polylinesState.carActiveRouteIndex);
                      context.read<ColourSyncState>().setColoursReady(true);
                    }
                  },
                  onTap: () {
                    setState(() {
                      polylinesState.setActiveRoute(index);
                    });
                    theme.setThemeColour(polylinesState.carActiveRouteIndex);
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
                                  size: 25,
                                ),
                              ),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    'via ${widget.polylinesState.routeSummary[index]}',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                    softWrap: true,
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
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: formatEmission(widget.vehicleState.getEmission(index)),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: SizedBox(width: 5),
                                    ),
                                    WidgetSpan(
                                      child: Image.asset(
                                        'assets/icons/co2e.png',
                                        width: 20,
                                        height: 20,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
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
                              ),
                              const SizedBox(height: 4),
                              TreeIcons(
                                treeIconName: widget.vehicleState.treeIcons,
                                settings: settings, // Pass settings to TreeIcons if needed
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _savedTripIds.contains(_indexToTripId[index] ?? -1) ? Icons.remove_circle_outline : Icons.add_circle_outline,
                                color: Colors.green,
                                size: 28,
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
                                size: 28,
                              ),
                              onPressed: settings.verifyLocation
                                  // If geolocation is ON => attempt location-based completion
                                  ? () => _attemptGeolocCompletion(index)
                                  // Otherwise => old behaviour, just toggle completion
                                  : () => _toggleTripCompletion(index),
                              tooltip: isCompleted ? 'Mark Incomplete' : 'Mark Complete',
                            ),
                            const SizedBox(height: 5),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(
                thickness: 2,
              ),
            ),
          ],
        );
      },
    );
  }
}
