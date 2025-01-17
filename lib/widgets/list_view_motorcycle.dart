import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/tree_icons.dart';

class MotorcycleListView extends StatefulWidget {
  const MotorcycleListView(
      {super.key,
      required this.vehicleState,
      required this.polylinesState,
      required this.icon});

  final dynamic vehicleState;
  final PolylinesState polylinesState;
  final IconData icon;

  @override
  State<MotorcycleListView> createState() => _MotorcycleListViewState();
}

class _MotorcycleListViewState extends State<MotorcycleListView> {
  final Set<int> _savedTripIds = {};
  final Map<int, int> _indexToTripId = {}; 

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
    final trip = Trip(
      date: DateTime.now().toIso8601String(),
      origin: widget.polylinesState.routeSummary[index],
      origLat: 0.0, // Placeholder 
      origLng: 0.0,
      destination: widget.polylinesState.routeSummary[index],
      destLat: 0.0,
      destLng: 0.0,
      distance: widget.polylinesState.distanceTexts[index],
      emissions: widget.vehicleState.getEmission(index).toDouble(),
      mode: "Motorcycle",
    );

    int id = await TripDatabase.instance.insertTrip(trip);

    setState(() {
      _savedTripIds.add(id);
      _indexToTripId[index] = id;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Trip saved to database with ID: $id")),
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
        SnackBar(content: Text("Trip deleted from database with ID: $tripId")),
      );
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

              selectedIndex = polylinesState.motorcycleActiveRouteIndex;

          
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
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
          ),
        ],
      );
    });
  }
}
