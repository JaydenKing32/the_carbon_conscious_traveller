import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/tree_icons.dart';

class MotorcycleListView extends StatefulWidget {
  const MotorcycleListView({
    super.key,
    required this.vehicleState,
    required this.polylinesState,
    required this.icon,
  });

  final dynamic vehicleState;
  final PolylinesState polylinesState;
  final IconData icon;

  @override
  State<MotorcycleListView> createState() => _MotorcycleListViewState();
}

class _MotorcycleListViewState extends State<MotorcycleListView> {
  final Set<int> _savedTripIds = {};
  final Map<int, int> _indexToTripId = {};
  final Map<int, bool> _tripCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSavedTrips();
  }
 Future<void> _saveTrip(int index) async {

    int maxEmission = widget.vehicleState.emissions.isNotEmpty
    ? widget.vehicleState.emissions.map((e) => e.toInt()).reduce((a, b) => a > b ? a : b)
    : 0;
    double selectedEmission = widget.vehicleState.getEmission(index).toDouble();
    double reduction = max(0, maxEmission - selectedEmission);
    String motoModel = widget.vehicleState.selectedValue.toString().split('.').last;
    motoModel = motoModel[0].toUpperCase() + motoModel.substring(1);

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
      mode: "Motorcycle",
      reduction: reduction,
      complete: false,
      model: motoModel,
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
  Future<void> _loadSavedTrips() async {
    List<Trip> trips = await TripDatabase.instance.getAllTrips();
    setState(() {
      _savedTripIds.clear();
      _indexToTripId.clear();
      _tripCompletionStatus.clear();
      for (var trip in trips) {
        _savedTripIds.add(trip.id!);
        _indexToTripId[trip.id!] = trip.id!;
        _tripCompletionStatus[trip.id!] = trip.complete;
      }
    });
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
    return Consumer<PolylinesState>(builder: (context, polylinesState, child) {
      return Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: widget.polylinesState.resultForPrivateVehicle.length,
            itemBuilder: (BuildContext context, int index) {
              widget.vehicleState.getTreeIcons(index);

              int? tripId = _indexToTripId[index];
              bool isCompleted = tripId != null ? _tripCompletionStatus[tripId] ?? false : false;

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
                      Expanded(
                        flex: 2,
                        child: Row(
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
                                          .bodyLarge,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(formatEmission(
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
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isCompleted ? Icons.check_circle : Icons.cancel_outlined,
                              color: isCompleted ? Colors.green : Colors.black,
                              size: 28,
                            ),
                            onPressed: () => _toggleTripCompletion(index),
                          ),

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
                          ),
                          const SizedBox(width: 5),
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
    });
  }
}