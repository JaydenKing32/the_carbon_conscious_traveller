import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';
import 'package:the_carbon_conscious_traveller/state/private_motorcycle_state.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/tree_icons.dart';

class MotorcycleListView extends StatefulWidget {
  const MotorcycleListView({
    super.key,
    required this.vehicleState,
    required this.polylinesState,
    required this.icon,
  });

  final PrivateMotorcycleState vehicleState; // Specific type instead of dynamic
  final PolylinesState polylinesState;
  final IconData icon;

  @override
  State<MotorcycleListView> createState() => _MotorcycleListViewState();
}

class _MotorcycleListViewState extends State<MotorcycleListView> {
  final Set<int> _savedTripIds = {};
  final Map<String, int> _routeToTripId = {}; // Map route summary to trip ID
  final Map<int, bool> _tripCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSavedTrips();
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

    String motoModel = widget.vehicleState.selectedValue.toString().split('.').last;
    if (motoModel.isNotEmpty) {
      motoModel = motoModel[0].toUpperCase() + motoModel.substring(1);
    }

    final trip = Trip(
      date: DateTime.now().toIso8601String(),
      origin: route,
      origLat: 0.0, // Replace with actual origin latitude
      origLng: 0.0, // Replace with actual origin longitude
      destination: route, // Assuming route uniquely defines origin and destination
      destLat: 0.0, // Replace with actual destination latitude
      destLng: 0.0, // Replace with actual destination longitude
      distance: widget.polylinesState.distanceTexts[index],
      emissions: widget.vehicleState.getEmission(index).toDouble(),
      mode: "Motorcycle",
      reduction: reduction,
      complete: false,
      model: motoModel,
    );

    int id = await TripDatabase.instance.insertTrip(trip);
    setState(() {
      _savedTripIds.add(id);
      _routeToTripId[route] = id;
    });
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

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

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

  @override
  Widget build(BuildContext context) {
    return Consumer2<PolylinesState, Settings>(
      builder: (context, polylinesState, settings, child) {
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
                Color color = Colors.transparent;
                if (selectedIndex == index) {
                  color = Colors.green;
                } else {
                  color = Colors.transparent;
                }
                // Fetch tree icons based on emission
                widget.vehicleState.getTreeIcons(index, context);

                return InkWell(
                  onTap: () {
                    setState(() {
                      polylinesState.setActiveRoute(index);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: color,
                          width: 4.0,
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
                                  color: Colors.green,
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
                                isCompleted ? Icons.check_circle : Icons.cancel_outlined,
                                color: isCompleted ? Colors.green : Colors.black,
                                size: 28,
                              ),
                              onPressed: settings.enableGeolocationVerification
                                  // If geolocation is ON => attempt location-based completion
                                  ? () => _attemptGeolocCompletion(index)
                                  // Otherwise => old behavior, just toggle completion
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
              separatorBuilder: (BuildContext context, int index) => const Divider(),
            ),
          ],
        );
      },
    );
  }
}
