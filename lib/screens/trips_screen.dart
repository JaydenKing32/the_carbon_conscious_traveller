import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late Future<List<Trip>> _trips;

  @override
  void initState() {
    super.initState();
    _trips = TripDatabase.instance.getAllTrips();
  }

  /// Deletes a trip and refreshes the list
  void _deleteTrip(int id) async {
    await TripDatabase.instance.deleteTrip(id);
    setState(() {
      _trips = TripDatabase.instance.getAllTrips();
    });
  }

  /// Returns the correct transport icon based on mode
  IconData _getTransportIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'motorcycle':
        return Icons.sports_motorsports;
      case 'transit':
        return Icons.train;
      default:
        return Icons.help_outline;
    }
  }

  /// Formats emissions (g vs. kg)
  String _formatEmissions(double emissions) {
    return emissions >= 1000
        ? '${(emissions / 1000).toStringAsFixed(2)} kg'
        : '${emissions.round()} g';
  }

  /// Formats date from ISO string to YYYY-MM-DD
  String _formatDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trips"),
        backgroundColor: const Color.fromARGB(255, 7, 179, 110), 
      ),
      body: FutureBuilder<List<Trip>>(
        future: _trips,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No trips found."));
          }
          return ListView.separated(
            itemCount: snapshot.data!.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final trip = snapshot.data![index];
              return ListTile(
                leading: Icon(
                  _getTransportIcon(trip.mode),
                  size: 32,
                ),
                title: Text(
                  trip.destination,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Date: ${_formatDate(trip.date)}"), 
                   Text.rich(
                      TextSpan(
                        text: "Emissions: ",
                        children: [
                          TextSpan(
                            text: _formatEmissions(trip.emissions),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),],),)
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteTrip(trip.id!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
