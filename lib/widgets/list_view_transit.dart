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
import 'package:auto_size_text/auto_size_text.dart';

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

  @override
  Widget build(BuildContext context) {
    TransitEmissionsCalculator? transitEmissionsCalculator =
        TransitEmissionsCalculator();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      TransitState transitState =
          Provider.of<TransitState>(context, listen: false);
      transitState.updateTransitEmissions(widget.emissions);
    });
return Consumer<PolylinesState>(
  builder: (context, polylinesState, child) {
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
            List<double> stepEmissions =
                transitEmissionsCalculator.calculateStepEmissions(steps);

            int selectedIndex = polylinesState.transitActiveRouteIndex;
            int? sIndex = _indexToTripId[index];
            bool isCompleted =
                sIndex != null ? _tripCompletionStatus[sIndex] ?? false : false;

            Color color = selectedIndex == index ? Colors.green : Colors.transparent;

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
                                legs.first.departureTime?.text == null
                                    ? ""
                                    : "${legs.first.departureTime?.text} - ${legs.first.arrivalTime?.text}",
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
              width: MediaQuery.of(context).size.width * 0.06,  // Adjust dynamically
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
          treeIconName: upDateTreeIcons(
            widget.emissions.map((e) => e.toInt()).toList(),
            index,
          ),
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
                            _savedTripIds.contains(_indexToTripId[index] ?? -1)
                                ? Icons.remove_circle_outline
                                : Icons.add_circle_outline,
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
                          tooltip: _savedTripIds.contains(_indexToTripId[index] ?? -1)
                              ? 'Удалить поездку'
                              : 'Сохранить поездку',
                        ),
                        IconButton(
                          icon: Icon(
                            isCompleted ? Icons.check_circle : Icons.cancel_outlined,
                            color: isCompleted ? Colors.green : Colors.black,
                            size: screenWidth * 0.07, // Scaled size
                          ),
                          onPressed: () => _toggleTripCompletion(index),
                          tooltip:
                              isCompleted ? 'Отметить как незавершённое' : 'Отметить как завершённое',
                        ),
                        SizedBox(height: screenHeight * 0.005),
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
