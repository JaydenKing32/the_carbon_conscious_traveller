import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Trip> _completedTrips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    List<Trip> allTrips = await TripDatabase.instance.getAllTrips();
    setState(() {
      _completedTrips = allTrips
          .where((trip) => trip.complete && _isSameMonthYear(trip.date))
          .toList();
    });
  }


  bool _isSameMonthYear(String tripDate) {
    DateTime tripDateTime = DateTime.parse(tripDate);
    return tripDateTime.year == _selectedDate.year &&
        tripDateTime.month == _selectedDate.month;
  }

  
  void _changeMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + delta, 1);
      _loadTrips();
    });
  }


  Map<int, Map<String, double>> _aggregateData() {
    Map<int, Map<String, double>> dailyEmissions = {};

    for (var trip in _completedTrips) {
      DateTime tripDate = DateTime.parse(trip.date);
      int day = tripDate.day;

      if (!dailyEmissions.containsKey(day)) {
        dailyEmissions[day] = {'emissions': 0.0, 'reduction': 0.0};
      }

      dailyEmissions[day]!['emissions'] =
          (dailyEmissions[day]!['emissions'] ?? 0) + trip.emissions;
      dailyEmissions[day]!['reduction'] =
          (dailyEmissions[day]!['reduction'] ?? 0) + trip.reduction;
    }

    return dailyEmissions;
  }

  double _calculateTotalDistance() {
    return _completedTrips.fold(0, (sum, trip) {
      double distance = double.tryParse(trip.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      return sum + distance;
    });
  }

  String _getFunFact(double distance) {
    if (distance < 1) {
      return "You're just getting started! 🏁";
    } else if (distance < 5) {
      return "That's about the length of the Golden Gate Bridge 🌉";
    } else if (distance < 42) {
      return "You've traveled more than a marathon! 🏃‍♂️";
    } else if (distance < 500) {
      return "That's almost the distance from Sydney to Melbourne! 🏙️🚆";
    } else if (distance < 384400) {
      return "That's almost the distance to the Moon! 🌙🚀";
    } else {
      return "You've traveled a distance beyond Earth's orbit! 🛰️";
    }
  }
@override
  Widget build(BuildContext context) {
    String formattedMonth = DateFormat('MMMM yyyy').format(_selectedDate);
    Map<int, Map<String, double>> dailyData = _aggregateData();
    double totalDistance = _calculateTotalDistance();
    String funFact = _getFunFact(totalDistance);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
        backgroundColor: const Color.fromARGB(255, 7, 179, 110),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Facts Container with row-based text + emoji inline
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Distance traveled + earth emoji on the same line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          "You consciously traveled about "
                          "${totalDistance.toStringAsFixed(1)} km!",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Earth emoji sized the same as the text
                      const Text(
                        "🌏",
                        style: TextStyle(
                          fontSize: 14, // matches text style
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Fun fact + rocket emoji inline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          funFact,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left, size: 30),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  formattedMonth,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right, size: 30),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Chart
            Expanded(
              child: _completedTrips.isEmpty
                  ? const Center(
                      child: Text("No data available for this time period"),
                    )
                  : SfCartesianChart(
                      primaryXAxis: const NumericAxis(
                        title: AxisTitle(text: "Day"),
                      ),
                      primaryYAxis: const NumericAxis(
                        title: AxisTitle(text: "kg CO₂e"),
                      ),
                      legend: const Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series:
                          <CartesianSeries<MapEntry<int, Map<String, double>>, int>>[
                        ColumnSeries<MapEntry<int, Map<String, double>>, int>(
                          name: "Emissions",
                          dataSource: dailyData.entries.toList(),
                          xValueMapper: (entry, _) => entry.key,
                          yValueMapper: (entry, _) => entry.value['emissions'],
                          color: Colors.yellow,
                          width: 0.7,
                        ),
                        ColumnSeries<MapEntry<int, Map<String, double>>, int>(
                          name: "Reduction",
                          dataSource: dailyData.entries.toList(),
                          xValueMapper: (entry, _) => entry.key,
                          yValueMapper: (entry, _) => entry.value['reduction'],
                          color: Colors.green,
                          width: 0.7,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}