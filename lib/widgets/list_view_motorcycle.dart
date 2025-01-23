// motorcycle_list_view.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';
import 'package:the_carbon_conscious_traveller/state/private_motorcycle_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/tree_icons.dart';

class MotorcycleListView extends StatefulWidget {
  const MotorcycleListView({
    Key? key,
    required this.vehicleState,
    required this.polylinesState,
    required this.icon,
  }) : super(key: key);

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
      print("Invalid index: $index");
      return;
    }

    String route = widget.polylinesState.routeSummary[index];
    // Check if a trip for this route already exists
    if (_routeToTripId.containsKey(route)) {
      // Trip already exists, do not save again
      print("Trip for route '$route' already exists.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Trip for route '$route' already exists."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int maxEmission = widget.vehicleState.emissions.isNotEmpty
        ? widget.vehicleState.emissions.map((e) => e.toInt()).reduce(max)
        : 0;
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

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Trip for route '$route' saved successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Deletes a trip from the database and updates the local state.
  Future<void> _deleteTrip(int index) async {
    if (!_isValidIndex(index)) {
      print("Invalid index: $index");
      return;
    }

    String route = widget.polylinesState.routeSummary[index];
    if (!_routeToTripId.containsKey(route)) {
      print("No trip found for route: $route");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No trip found for route: $route"),
          backgroundColor: Colors.red,
        ),
      );
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

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Trip for route '$route' deleted successfully!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Toggles the completion status of a trip.
  Future<void> _toggleTripCompletion(int index) async {
    if (!_isValidIndex(index)) {
      print("Invalid index: $index");
      return;
    }

    String route = widget.polylinesState.routeSummary[index];
    if (!_routeToTripId.containsKey(route)) {
      print("No trip found for route: $route");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No trip found for route: $route"),
          backgroundColor: Colors.red,
        ),
      );
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

        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Trip for route '$route' marked as ${newStatus ? 'completed' : 'incomplete'}."),
            backgroundColor: Colors.blue,
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
    return Consumer<PolylinesState>(
      builder: (context, polylinesState, child) {
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
                  return const SizedBox.shrink(); // Or display a placeholder widget
                }

                // Fetch the trip ID and completion status for the current route
                String route = widget.polylinesState.routeSummary[index];
                int? tripId = _routeToTripId[route];
                bool isCompleted =
                    tripId != null ? _tripCompletionStatus[tripId] ?? false : false;

                // Fetch tree icons based on emission
                widget.vehicleState.getTreeIcons(index);

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
                          color: isCompleted ? Colors.green : Colors.transparent,
                          width: 4.0,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon and Route Summary
                        Expanded(
                          flex: 2,
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
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 30),
                                  child: Text(
                                    'via ${widget.polylinesState.routeSummary[index]}',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Emissions, Distance, Duration, and Tree Icons
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    formatEmission(
                                      widget.vehicleState.getEmission(index),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Image.asset(
                                    'assets/icons/co2e.png',
                                    width: 30,
                                    height: 30,
                                  ),
                                ],
                              ),
                              Text(
                                widget.polylinesState.distanceTexts[index],
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                widget.polylinesState.durationTexts[index],
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              //TreeIcons(
                               // treeIconName:
                              //      widget.vehicleState.treeIcons[index],
                              //),
                            ],
                          ),
                        ),
                        // Action Buttons: Complete and Save/Delete
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.cancel_outlined,
                                color: isCompleted ? Colors.green : Colors.black,
                                size: 28,
                              ),
                              onPressed: () => _toggleTripCompletion(index),
                            ),
                            IconButton(
                              icon: Icon(
                                _savedTripIds
                                        .contains(_routeToTripId[route] ?? -1)
                                    ? Icons.remove_circle_outline
                                    : Icons.add_circle_outline,
                                color: Colors.green,
                                size: 28,
                              ),
                              onPressed: () {
                                if (_savedTripIds
                                    .contains(_routeToTripId[route] ?? -1)) {
                                  _deleteTrip(index);
                                } else {
                                  _saveTrip(index);
                                }
                              },
                            ),
                            const SizedBox(width: 5),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(),
            ),
          ],
        );
      },
    );
  }
}
