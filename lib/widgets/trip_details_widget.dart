import 'package:flutter/material.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';

class TripDetailsWidget extends StatelessWidget {
  final Trip trip;

  const TripDetailsWidget({super.key, required this.trip});

  String _formatEmissions(double emissions) {
    return emissions >= 1000
        ? '${(emissions / 1000).toStringAsFixed(2)} kg'
        : '${emissions.round()} g';
  }

  String _formatDistance(String distance) {
    if (distance.contains("m") || distance.contains("km")) return distance;
    double meters = double.tryParse(distance) ?? 0;
    return meters >= 1000
        ? "${(meters / 1000).toStringAsFixed(1)} km"
        : "$meters m";
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Trip Details",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
              ),
              const SizedBox(height: 8),

              // Date
              _infoRow("Date", trip.date.split("T").first),

              // Origin
              _infoRow("Origin", trip.origin),

              // Destination
              _infoRow("Destination", trip.destination),

              // Mode of Transport
              _infoRow("Mode", trip.mode),

              // Distance
              _infoRow("Distance", _formatDistance(trip.distance)),

              // Emissions
              _infoRow(
                "Emissions",
                _formatEmissions(trip.emissions),
                isBold: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
