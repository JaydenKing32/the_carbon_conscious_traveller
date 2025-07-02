import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/helpers/dynamo_helper.dart';
import 'package:the_carbon_conscious_traveller/models/dynamo_trip.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/state/theme_state.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _EventScreenState();
  }
}

class _EventScreenState extends State<EventScreen> {
  // final Set<DynamoTrip> _trips = {};
  final Set<String> _deviceIds = {};
  int _totalDistance = 0;
  double _totalEmissions = 0;
  double _totalReduction = 0;
  int _minDistance = 0;
  int _maxDistance = 0;
  double _transitPercent = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedTrips();
  }

  Future<void> _loadSavedTrips() async {
    List<DynamoTrip> trips = await DynamoHelper.getAll();
    setState(() {
      _deviceIds.clear();

      _totalDistance = 0;
      _totalEmissions = 0;
      _totalReduction = 0;
      _minDistance = 0x7fffffff; // no MAX_INT, so use a large number
      _maxDistance = 0;
      int transitCount = 0;

      for (var trip in trips) {
        // _trips.add(trip);
        _deviceIds.add(trip.deviceId);
        _totalDistance += trip.distance;
        _totalEmissions += trip.emissions;
        _totalReduction += trip.reduction;
        if (trip.distance < _minDistance) {
          _minDistance = trip.distance;
        }
        if (trip.distance > _maxDistance) {
          _maxDistance = trip.distance;
        }
        if (trip.mode == "Transit") {
          transitCount++;
        }
      }
      _transitPercent = transitCount / trips.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context);
    const textSize = 0.04;

    return Center(child: Consumer<ThemeState>(builder: (BuildContext context, theme, child) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Event'),
          ),
          body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(children: [
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Geolocation Settings',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text('Enable Event Mode', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04)),
                          subtitle: Text('Enable data collection for event mode', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035)),
                          value: settings.enableGeolocationVerification,
                          onChanged: (bool value) {
                            settings.toggleGeolocationVerification(value);
                          },
                        )
                      ],
                    ),
                  ),
                ),
                Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("Number of participants: ${_deviceIds.length}", style: TextStyle(fontSize: MediaQuery.of(context).size.width * textSize)),
                          Text("Total distance travelled: ${(_totalDistance / 1000).toStringAsFixed(0)}km", style: TextStyle(fontSize: MediaQuery.of(context).size.width * textSize)),
                          Text("Total emissions: ${(_totalEmissions / 1000).toStringAsFixed(0)}kg", style: TextStyle(fontSize: MediaQuery.of(context).size.width * textSize)),
                          Text("Total emission reduction: ${(_totalReduction / 1000).toStringAsFixed(0)}kg", style: TextStyle(fontSize: MediaQuery.of(context).size.width * textSize)),
                          Text("Shortest travel distance: ${(_minDistance / 1000).toStringAsFixed(2)}km", style: TextStyle(fontSize: MediaQuery.of(context).size.width * textSize)),
                          Text("Longest travel distance: ${(_maxDistance / 1000).toStringAsFixed(2)}km", style: TextStyle(fontSize: MediaQuery.of(context).size.width * textSize)),
                          Text("Trips that used public transport: ${(_transitPercent * 100).toStringAsFixed(2)}%", style: TextStyle(fontSize: MediaQuery.of(context).size.width * textSize)),
                        ])))
              ])));
    }));
  }
}
