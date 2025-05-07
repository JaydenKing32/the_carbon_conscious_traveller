import 'package:flutter/material.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/theme_state.dart';

class TransitSteps extends StatelessWidget {
  const TransitSteps({super.key, required this.steps, required this.stepEmissions});

  final List<dynamic> steps;
  final List<double> stepEmissions;

  Color parseColor(String? colorString, Color defaultColor) {
    if (colorString != null) {
      return Color(int.parse(colorString.replaceAll('#', '0xff')));
    }
    return defaultColor;
  }

  String formatNumber(double number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)} kg';
    } else {
      return '${number.round()} g';
    }
  }

  Widget _buildStepIcon(BuildContext context, dynamic step) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    var shortNameText = step.transit?.line?.shortName ?? step.transit?.line?.name;

    if (step.transit?.line?.vehicle?.icon == null && step.travelMode == TravelMode.walking) {
      return Consumer<ThemeState>(
        builder: (context, theme, child) { 
        return Column(
          children: [
            Icon(Icons.directions_walk, size: screenWidth * 0.05), // Smaller walk icon
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.002),
              child: AutoSizeText(
                formatNumber(stepEmissions[steps.indexOf(step)]),
                style: Theme.of(context).textTheme.bodySmall,
                minFontSize: 8, // Smaller text
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(right: screenWidth * 0.015),
        child: Column(
          children: [
            Wrap(
              children: [
                // Transit Icon
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
                  child: Image.network(
                    "https:${step.transit?.line?.vehicle?.localIcon ?? step.transit?.line?.vehicle?.icon}",
                    width: screenWidth * 0.05, // Smaller transit icon
                    height: screenWidth * 0.05,
                  ),
                ),
                // Bus Route Box
                Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015, vertical: screenHeight * 0.002),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: parseColor(step.transit?.line?.color, Colors.white),
                  ),
                  child: AutoSizeText(
                    shortNameText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.025, // Smaller text
                      color: step.transit?.line?.textColor != null ? parseColor(step.transit?.line?.textColor, Colors.black) : Colors.black,
                    ),
                    minFontSize: 8,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            // Emission Text
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.002),
              child: AutoSizeText(
                formatNumber(stepEmissions[steps.indexOf(step)]),
                style: Theme.of(context).textTheme.bodySmall,
                minFontSize: 8, // Smaller text
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    List<Widget> stepIcons = [];

    for (var step in steps) {
      stepIcons.add(
        Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.005),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display arrow only if not the first step
              if (steps.indexOf(step) != 0)
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.002, bottom: screenHeight * 0.035),
                  child: Icon(Icons.arrow_forward_ios, size: screenWidth * 0.025), // Smaller arrow
                ),
              _buildStepIcon(context, step),
            ],
          ),
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: screenWidth * 0.01,
      children: stepIcons,
    );
  }
}
