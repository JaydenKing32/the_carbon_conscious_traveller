import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/tree_icons.dart';

class CarListView extends StatefulWidget {
  const CarListView({
    super.key,
    required this.vehicleState,
    required this.polylinesState,
    required this.icon,
  });

  final dynamic vehicleState;
  final PolylinesState polylinesState;
  final IconData icon;

  @override
  State<CarListView> createState() => _CarListViewState();
}

class _CarListViewState extends State<CarListView> {
  final Set<int> _savedTripIds = {}; 
  final Map<int, int> _indexToTripId = {}; 
  final Map<int, bool> _tripCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSavedTrips();
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

    int maxEmission = widget.vehicleState.emissions.isNotEmpty
        ? widget.vehicleState.emissions.map((e) => e.toInt()).reduce((a, b) => a > b ? a : b)
        : 0;
    double selectedEmission = widget.vehicleState.getEmission(index).toDouble();
    double reduction = max(0, maxEmission - selectedEmission);
    String carModel = "${widget.vehicleState.selectedSize?.toString().split('.').last} - ${widget.vehicleState.selectedFuelType?.toString().split('.').last}";

    final trip = Trip(
      date: DateTime.now().toIso8601String(),
      origin: widget.polylinesState.routeSummary[index],
      origLat: 0.0,
      origLng: 0.0,
      destination: widget.polylinesState.routeSummary[index],
      destLat: 0.0,
      destLng: 0.0,
      distance: widget.polylinesState.distanceTexts[index],
      emissions: widget.vehicleState.getEmission(index).toDouble(),
      mode: "Car",
      reduction: reduction,
      complete: false,
      model: carModel
    );

    int id = await TripDatabase.instance.insertTrip(trip);

    setState(() {
      _savedTripIds.add(id);
      _indexToTripId[index] = id;
    });
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

  String formatEmission(int emission) {
    if (emission >= 1000) {
      return "${(emission / 1000).toStringAsFixed(2)} kg";
    } else {
      return "$emission g";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PolylinesState, Settings>(
       builder: (context, polylinesState, settings, child) {
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
                        ),);
                }
                 int selectedIndex;
               widget.vehicleState.getTreeIcons(index, context);

                int? tripId = _indexToTripId[index];
                bool isCompleted = tripId != null
                    ? _tripCompletionStatus[tripId] ?? false
                    : false;
                  //Change the border color of the active route

              selectedIndex = polylinesState.carActiveRouteIndex;
              Color color = Colors.transparent;
              if (selectedIndex == index) {
                color = Colors.green;
              } else {
                color = Colors.transparent;
              }
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
                              size: 25,
                            ),
                          ),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10), 
                              child: Text(
                                'via ${widget.polylinesState.routeSummary[index]}',
                                style: Theme.of(context).textTheme.bodyLarge,
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
                            _savedTripIds.contains(_indexToTripId[index] ?? -1)
                                ? Icons.remove_circle_outline
                                : Icons.add_circle_outline,
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
                          tooltip: _savedTripIds.contains(_indexToTripId[index] ?? -1)
                              ? 'Удалить поездку'
                              : 'Сохранить поездку',
                        ),
                        IconButton(
                          icon: Icon(
                            isCompleted ? Icons.check_circle : Icons.cancel_outlined,
                            color: isCompleted ? Colors.green : Colors.black,
                            size: 28,
                          ),
                          onPressed: () => _toggleTripCompletion(index),
                          tooltip: isCompleted ? 'Отметить как незавершённое' : 'Отметить как завершённое',
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
/*
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';
import 'package:the_carbon_conscious_traveller/widgets/tree_icons.dart';

class CarListView extends StatefulWidget {
  const CarListView({
    super.key,
    required this.vehicleState,
    required this.polylinesState,
    required this.icon,
  });

  final dynamic vehicleState;
  final PolylinesState polylinesState;
  final IconData icon;

  @override
  State<CarListView> createState() => _CarListViewState();
}

class _CarListViewState extends State<CarListView> {
  final Set<int> _savedTripIds = {}; 
  final Map<int, int> _indexToTripId = {}; 
  final Map<int, bool> _tripCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSavedTrips();
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

    int maxEmission = widget.vehicleState.emissions.isNotEmpty
        ? widget.vehicleState.emissions.map((e) => e.toInt()).reduce((a, b) => a > b ? a : b)
        : 0;
    double selectedEmission = widget.vehicleState.getEmission(index).toDouble();
    double reduction = max(0, maxEmission - selectedEmission);
    String carModel = "${widget.vehicleState.selectedSize?.toString().split('.').last} - ${widget.vehicleState.selectedFuelType?.toString().split('.').last}";

    final trip = Trip(
      date: DateTime.now().toIso8601String(),
      origin: widget.polylinesState.routeSummary[index],
      origLat: 0.0,
      origLng: 0.0,
      destination: widget.polylinesState.routeSummary[index],
      destLat: 0.0,
      destLng: 0.0,
      distance: widget.polylinesState.distanceTexts[index],
      emissions: widget.vehicleState.getEmission(index).toDouble(),
      mode: "Car",
      reduction: reduction,
      complete: false,
      model: carModel
    );

    int id = await TripDatabase.instance.insertTrip(trip);

    setState(() {
      _savedTripIds.add(id);
      _indexToTripId[index] = id;
    });
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
  @override
  Widget build(BuildContext context) {
    String formatNumber(int number) {
      if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(2)} kg';
      } else {
        return '${number.round()} g';
      }
    }

    int selectedIndex;

    return Consumer(builder: (context, PolylinesState polylinesState, child) {
      return Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: widget.polylinesState.resultForPrivateVehicle.length,
            itemBuilder: (BuildContext context, int index) {
              widget.vehicleState.getTreeIcons(index);

              selectedIndex = polylinesState.carActiveRouteIndex;
              int? tripId = _indexToTripId[index];
                bool isCompleted = tripId != null
                    ? _tripCompletionStatus[tripId] ?? false
                    : false;
              //Change the border color of the active route
              Color color = Colors.transparent;
              if (selectedIndex == index) {
                color = Colors.green;
              } else {
                color = Colors.transparent;
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                  polylinesState.setActiveRoute(selectedIndex);
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Icon(widget.icon,
                                      color: Colors.green, size: 30),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 30),
                                    child: Text(
                                        'via ${widget.polylinesState.routeSummary[index]}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(formatNumber(
                                    widget.vehicleState.getEmission(index))),
                                Image.asset('assets/icons/co2e.png',
                                    width: 30, height: 30),
                              ],
                            ),
                            Text(widget.polylinesState.distanceTexts[index],
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(widget.polylinesState.durationTexts[index],
                                style: Theme.of(context).textTheme.bodySmall),
                            TreeIcons(
                                treeIconName: widget.vehicleState.treeIcons),
                          ],
                        ),
                      ),
                      Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _savedTripIds.contains(_indexToTripId[index] ?? -1)
                                ? Icons.remove_circle_outline
                                : Icons.add_circle_outline,
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
                          tooltip: _savedTripIds.contains(_indexToTripId[index] ?? -1)
                              ? 'Удалить поездку'
                              : 'Сохранить поездку',
                        ),
                        IconButton(
                          icon: Icon(
                            isCompleted ? Icons.check_circle : Icons.cancel_outlined,
                            color: isCompleted ? Colors.green : Colors.black,
                            size: 28,
                          ),
                          onPressed: () => _toggleTripCompletion(index),
                          tooltip: isCompleted ? 'Отметить как незавершённое' : 'Отметить как завершённое',
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
                const Divider(),
          ),
        ],
      );
    });
  }
}*/