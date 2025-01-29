import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/trip_details_widget.dart';

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
    _loadTrips();
  }

  void _loadTrips() {
    setState(() {
      _trips = TripDatabase.instance.getAllTrips();
    });
  }

  void _deleteTrip(int id) async {
    await TripDatabase.instance.deleteTrip(id);
    _loadTrips();
  }

  Future<void> _toggleTripCompletion(int id, bool currentStatus) async {
    await TripDatabase.instance.updateTripCompletion(id, !currentStatus);
    _loadTrips();
  }

  Future<void> _attemptGeolocCompletion(Trip trip) async {
    // If already complete, do nothing
    if (trip.complete) return;

    // Get user's current location (make sure you have permission logic in place)
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    // Compare distance to trip's destination lat/lng
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      trip.destLat,
      trip.destLng,
    );

    const double thresholdMeters = 50.0;
    if (distanceInMeters <= thresholdMeters) {
      // Mark trip as complete
      await TripDatabase.instance.updateTripCompletion(trip.id!, true);
      _loadTrips();
    } else {
      // Show message if not close enough
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have not reached the destination."),
        ),
      );
    }
  }
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

  String _formatEmissions(double emissions) {
    return emissions >= 1000
        ? '${(emissions / 1000).toStringAsFixed(2)} kg'
        : '${emissions.round()} g';
  }

  String _formatDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {

    final settings = Provider.of<Settings>(context);

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

              Color statusColor = trip.complete ? Colors.green : Colors.black;

              return ListTile(
                leading: Icon(
                  _getTransportIcon(trip.mode),
                  size: 32,
                  color: statusColor,
                ),
                title: Text(
                  trip.destination,
                  style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    
                    IconButton(
                      icon: Icon(
                        trip.complete ? Icons.check_circle : Icons.cancel_outlined,
                        color: trip.complete ? Colors.green : Colors.black,
                      ),
                     onPressed: settings.enableGeolocationVerification
                                  ? () => _attemptGeolocCompletion(trip)
                                  : () => _toggleTripCompletion(trip.id!, trip.complete),
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.black),
                      onPressed: () => _deleteTrip(trip.id!),
                    ),
                  ],
                ),
                onTap: () => _showTripDetails(context, trip),
              );
            },
          );
        },
      ),
    );
  }

  void _showTripDetails(BuildContext context, Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows more flexible height usage
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6, // 80% of the screen height
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: TripDetailsWidget(trip: trip),
              ),
            ],
          ),
        );
      },
    );
  }
}
