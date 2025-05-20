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
  DateTime _currentStartDate = DateTime.now(); // Track window start date
  List<Trip> _completedTrips = [];

  @override
  void initState() {
    super.initState();
    _currentStartDate = _getInitialStartDate();
    _loadTrips();
  }

  DateTime _getInitialStartDate() {
    final now = DateTime.now();
    return now.subtract(const Duration(days: 1)); // Start from yesterday
  }

  Future<void> _loadTrips() async {
    List<Trip> allTrips = await TripDatabase.instance.getAllTrips();
    setState(() {
      _completedTrips = allTrips.where((trip) => trip.complete && _isSameMonthYear(trip.date)).toList();
    });
  }

  bool _isSameMonthYear(String tripDate) {
    DateTime tripDateTime = DateTime.parse(tripDate);
    return tripDateTime.year == _selectedDate.year && tripDateTime.month == _selectedDate.month;
  }

  void _changeMonth(int delta) {
    final newDate = DateTime(_selectedDate.year, _selectedDate.month + delta, 1);
    final now = DateTime.now();

    setState(() {
      _selectedDate = newDate;

      // Check if the new month is the current month
      if (newDate.year == now.year && newDate.month == now.month) {
        // For current month, start from yesterday
        _currentStartDate = now.subtract(const Duration(days: 1));
      } else {
        // For other months, start from first day
        _currentStartDate = DateTime(newDate.year, newDate.month, 1);
      }

      _loadTrips();
    });
  }

  void _moveWindow(int delta) {
    setState(() {
      _currentStartDate = _currentStartDate.add(Duration(days: delta));
    });
  }

  double _calculateTotalDistance() {
    return _completedTrips.fold(0, (sum, trip) {
      return sum + trip.distance;
    });
  }

  String _getFunFact(double distance) {
    if (distance < 1) {
      return "You're just getting started! 🏁";
    } else if (distance < 5000) {
      return "That's about the length of the Golden Gate Bridge 🌉";
    } else if (distance < 42000) {
      return "You've travelled more than a marathon! 🏃‍♂️";
    } else if (distance < 892000) {
      return "That's almost the distance from Sydney to Melbourne! 🏙️🚆";
    } else if (distance < 384400000) {
      return "That's almost the distance to the Moon! 🌙🚀";
    } else {
      return "You've travelled a distance beyond Earth's orbit! 🛰️";
    }
  }

  Map<int, Map<String, double>> _aggregateData() {
    final Map<int, Map<String, double>> dailyEmissions = {};

    for (final trip in _completedTrips) {
      final tripDate = DateTime.parse(trip.date);
      final day = tripDate.day;

      dailyEmissions[day] ??= {'emissions': 0.0, 'reduction': 0.0};
      dailyEmissions[day]!['emissions'] = (dailyEmissions[day]!['emissions'] ?? 0) + trip.emissions;
      dailyEmissions[day]!['reduction'] = (dailyEmissions[day]!['reduction'] ?? 0) + trip.reduction;
    }

    return dailyEmissions;
  }

  String _getWindowLabel() {
    final start = _currentStartDate;
    final end = _currentStartDate.add(const Duration(days: 2));
    return "${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}";
  }

  @override
  Widget build(BuildContext context) {
    final formattedMonth = DateFormat('MMMM yyyy').format(_selectedDate);
    final formattedMonthName = DateFormat('MMMM').format(_selectedDate);
    final dailyData = _aggregateData();
    double totalDistance = _calculateTotalDistance();
    String distanceStr;
    if (totalDistance < 1000) {
      distanceStr = "$totalDistance m";
    } else {
      distanceStr = "${(totalDistance / 1000).toStringAsFixed(1)} km";
    }
    String funFact = _getFunFact(totalDistance);

    // Generate data for 3-day window (including days from next month if needed)
    final Map<DateTime, Map<String, double>> filteredData = {};
    for (int i = 0; i < 3; i++) {
      final currentDay = _currentStartDate.add(Duration(days: i));
      final isInSelectedMonth = currentDay.month == _selectedDate.month;

      filteredData[currentDay] = isInSelectedMonth ? dailyData[currentDay.day] ?? {'emissions': 0.0, 'reduction': 0.0} : {'emissions': 0.0, 'reduction': 0.0};
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ... Keep your existing header widgets ...
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Distance travelled + earth emoji on the same line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          "In $formattedMonthName \nYou have consciously travelled: $distanceStr!",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Earth emoji sized the same as the text
                      const Text(
                        "🌏",
                        style: TextStyle(
                          fontSize: 12, // matches text style
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
            // Month navigation
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

            // Window label with month/day
            Text(
              _getWindowLabel(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Chart with swipe
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! > 0) {
                    _moveWindow(-1); // Swipe right
                  } else if (details.primaryVelocity! < 0) {
                    _moveWindow(1); // Swipe left
                  }
                },
                child: SfCartesianChart(
                  primaryXAxis: DateTimeAxis(
                    intervalType: DateTimeIntervalType.days,
                    dateFormat: DateFormat('d'),
                    majorGridLines: const MajorGridLines(width: 0),
                    minimum: _currentStartDate,
                    maximum: _currentStartDate.add(const Duration(days: 2)),
                  ),
                  primaryYAxis: const NumericAxis(
                    title: AxisTitle(text: "kg CO₂e"),
                    majorGridLines: MajorGridLines(width: 0),
                  ),
                  legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: [
                    ColumnSeries<MapEntry<DateTime, Map<String, double>>, DateTime>(
                      name: "Emissions",
                      dataSource: filteredData.entries.toList(),
                      xValueMapper: (entry, _) => entry.key,
                      yValueMapper: (entry, _) => entry.value['emissions'],
                      color: Colors.yellow,
                    ),
                    ColumnSeries<MapEntry<DateTime, Map<String, double>>, DateTime>(
                      name: "Reduction",
                      dataSource: filteredData.entries.toList(),
                      xValueMapper: (entry, _) => entry.key,
                      yValueMapper: (entry, _) => entry.value['reduction'],
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
