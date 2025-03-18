import 'package:flutter/material.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';

class TripDetailsWidget extends StatelessWidget {
  final Trip trip;

  const TripDetailsWidget({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Trip Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 7, 179, 110),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Status",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                trip.complete ? "✔ Completed" : "❌ Not Completed",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: trip.complete ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const Divider(),
          _tripDetailRow("Date", trip.date.substring(0, 10)),
          _tripDetailRow("Origin", trip.origin),
          _tripDetailRow("Destination", trip.destination),
          _tripDetailRow("Mode", trip.mode),
          _tripDetailRow("Type", trip.model),
          _tripDetailRow("Distance", trip.distanceString()),
          _tripDetailRow("Emissions", formatGrams(trip.emissions), isBold: true),
          _tripDetailRow("Reduction", formatGrams(trip.reduction), isBold: true, color: Colors.green),
        ],
      ),
    );
  }

  String formatGrams(double grams) {
    return grams >= 1000 ? '${(grams / 1000).toStringAsFixed(2)} kg' : '${grams.round()} g';
  }

  Widget _tripDetailRow(String title, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                color: color ?? Colors.black,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
