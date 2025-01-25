
import 'package:flutter/material.dart';
import 'package:the_carbon_conscious_traveller/data/flight.dart';


 String formatEmissionWithCO2(double grams, bool showUnit) {
  String formatted = "${grams.toStringAsFixed(2)} grams";
  if (showUnit) {
    formatted += " CO₂";
  }
  return formatted;
}

class EmissionDialog extends StatelessWidget {
  final Emissions emissions;
  final VoidCallback onCalculateAgain;

  const EmissionDialog({
    super.key,
    required this.emissions,
    required this.onCalculateAgain,
  });

  /// Helper method to convert grams to kilograms and format the emission value.
  String _formatEmission(double grams) {
    double kilograms = grams / 1000;
    return "${kilograms.toStringAsFixed(2)} kg CO₂";
  }

  /// Determines the emission values and assigns colors accordingly.
  List<Map<String, dynamic>> _getEmissionData() {
    Map<String, double> emissionMap = {
      "First Class": emissions.first,
      "Business Class": emissions.business,
      "Premium Economy": emissions.premiumEconomy,
      "Economy Class": emissions.economy,
    };

    // Find the smallest emission value
    double minEmission = emissionMap.values.reduce((a, b) => a < b ? a : b);

    // Assign colors: green for the smallest, others use predefined colors
    return emissionMap.entries.map((entry) {
      Color color = entry.value == minEmission ? Colors.green : _getColorForClass(entry.key);
      return {
        'class': entry.key,
        'emission': _formatEmission(entry.value),
        'color': color,
      };
    }).toList();
  }

  /// Assigns a distinct color for each cabin class (except the smallest, which is green).
  Color _getColorForClass(String cabinClass) {
    switch (cabinClass) {
      case "First Class":
        return Colors.black;
      case "Business Class":
        return Colors.black;
      case "Premium Economy":
        return Colors.black;
      case "Economy Class":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtain screen size for responsive text scaling
    double screenWidth = MediaQuery.of(context).size.width;

    // Determine base font size based on screen width
    double baseFontSize = screenWidth > 600 ? 20 : 16;

    List<Map<String, dynamic>> emissionData = _getEmissionData();

    return AlertDialog(
      title: const Text(
        "Flight Emissions by Class",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: emissionData.map((data) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Icon(
                    Icons.flight_takeoff,
                    color: data['color'],
                    size: baseFontSize + 4,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      data['class'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: baseFontSize,
                      ),
                    ),
                  ),
                  Text(
                    data['emission'],
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: baseFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCalculateAgain,
          child: const Text(
            "Calculate Again",
            style: TextStyle(fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            "Close",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}