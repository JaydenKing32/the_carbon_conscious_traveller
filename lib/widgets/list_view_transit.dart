import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/helpers/transit_emissions_calculator.dart';
import 'package:the_carbon_conscious_traveller/helpers/tree_icons_calculator.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/transit_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/transit_steps.dart';
import 'package:the_carbon_conscious_traveller/widgets/tree_icons.dart';

class TransitListView extends StatefulWidget {
  const TransitListView({
    super.key,
    required this.snapshot,
    required this.emissions,
  });

  final dynamic snapshot;
  final List<double> emissions;

  @override
  State<TransitListView> createState() => _TransitListViewState();
}

class _TransitListViewState extends State<TransitListView> {
  final Set<int> _savedTripIds = {}; // Store trip IDs from DB
  final Map<int, int> _indexToTripId = {}; // Maps UI index -> DB trip ID

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
     int maxEmission = widget.emissions.isNotEmpty
        ? widget.emissions.map((e) => e.toInt()).reduce(max)
        : 0;

    double selectedEmission = widget.emissions[index];
    double reduction = max(0, maxEmission - selectedEmission);

    final trip = Trip(
      date: DateTime.now().toIso8601String(),
      origin: widget.snapshot.data![index].legs.first.startAddress ?? "Unknown",
      origLat: 0,
      origLng: 0,
      destination:
          widget.snapshot.data![index].legs.first.endAddress ?? "Unknown",
      destLat: 0,
      destLng: 0,
      distance: widget.snapshot.data![index].legs.first.distance?.text ?? "0 km",
      emissions: widget.emissions[index],
      mode: "Transit",
      reduction: reduction,
      complete: false,
      model: "Public Transport",
    );

    int id = await TripDatabase.instance.insertTrip(trip);

    setState(() {
      _savedTripIds.add(id);
      _indexToTripId[index] = id;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Transit trip saved to database with ID: $id")),
    );
  }


  Future<void> _deleteTrip(int index) async {
    int? tripId = _indexToTripId[index];
    if (tripId != null && _savedTripIds.contains(tripId)) {
      await TripDatabase.instance.deleteTrip(tripId);
    

      setState(() {
        _savedTripIds.remove(tripId);
        _indexToTripId.remove(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transit trip deleted from database with ID: $tripId")),
      );
    } 
  }

  String formatNumber(double number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)} kg';
    } else {
      return '${number.round()} g';
    }
  }

  @override
  Widget build(BuildContext context) {
    TransitEmissionsCalculator? transitEmissionsCalculator =
        TransitEmissionsCalculator();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      TransitState transitState =
          Provider.of<TransitState>(context, listen: false);
      transitState.updateTransitEmissions(widget.emissions);
    });

    return Consumer<PolylinesState>(builder: (context, polylinesState, child) {
      return Column(
        children: [
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: widget.snapshot.data!.length,
            itemBuilder: (context, index) {
              List<dynamic> legs = widget.snapshot.data![index].legs;
              List<dynamic> steps = widget.snapshot.data![index].legs?.first.steps;
              List<double> stepEmissions =
                  transitEmissionsCalculator.calculateStepEmissions(steps);

              int selectedIndex = polylinesState.transitActiveRouteIndex;

              Color color = selectedIndex == index ? Colors.green : Colors.transparent;

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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 12, right: 20, top: 16, bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TransitSteps(
                                  steps: steps, stepEmissions: stepEmissions),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  legs.first.departureTime?.text == null
                                      ? ""
                                      : "${legs.first.departureTime?.text} - ${legs.first.arrivalTime?.text}",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(formatNumber(widget.emissions[index]),
                                      style: Theme.of(context).textTheme.bodyLarge),
                                  Image.asset('assets/icons/co2e.png',
                                      width: 30, height: 30),
                                ],
                              ),
                              Text("${legs.first.distance?.text}",
                                  style: Theme.of(context).textTheme.bodySmall),
                              Text("${legs.first.duration?.text}",
                                  style: Theme.of(context).textTheme.bodySmall),
                              TreeIcons(
                                  treeIconName: upDateTreeIcons(
                                      widget.emissions
                                          .map((e) => e.toInt())
                                          .toList(),
                                      index)),
                            ],
                          ),
                        ),
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
