import 'package:flutter/material.dart';
import 'package:google_directions_api/google_directions_api.dart';

class TransitSteps extends StatelessWidget {
  const TransitSteps(
      {super.key, required this.steps, required this.stepEmissions});

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
    // Display icon for walking steps
    var shortNameText =
        step.transit?.line?.shortName ?? step.transit?.line?.name;
    if (step.transit?.line?.vehicle?.icon == null &&
        step.travelMode == TravelMode.walking) {
      return Column(
        children: [
          const Icon(Icons.directions_walk),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              formatNumber(
                stepEmissions[steps.indexOf(step)],
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    } else if (step.transit?.line?.vehicle?.localIcon != null) {
      return Padding(
        // Display local icon for transit steps
        padding: const EdgeInsets.only(right: 5),
        child: Column(
          children: [
            Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Image.network(
                      "https:${step.transit?.line?.vehicle?.localIcon}",
                      width: 25),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: parseColor(step.transit?.line?.color, Colors.white),
                  ),
                  child: Text(
                    shortNameText,
                    style: TextStyle(
                        color: step.transit?.line?.textColor != null
                            ? parseColor(
                                step.transit?.line?.textColor, Colors.black)
                            : Colors.black,
                        backgroundColor: parseColor(
                          step.transit?.line?.color,
                          Colors.white,
                        )),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                formatNumber(stepEmissions[steps.indexOf(step)]),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        // Display icon for transit steps if local icon doesn't exist
        padding: const EdgeInsets.only(right: 5),
        child: Column(
          children: [
            Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Image.network(
                      "https:${step.transit?.line?.vehicle?.icon}",
                      width: 25),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: parseColor(step.transit?.line?.color, Colors.white),
                  ),
                  child: Text(
                    shortNameText,
                    style: TextStyle(
                      color: step.transit?.line?.textColor != null
                          ? parseColor(
                              step.transit?.line?.textColor, Colors.black)
                          : Colors.black,
                      backgroundColor:
                          parseColor(step.transit?.line?.color, Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                formatNumber(stepEmissions[steps.indexOf(step)]),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stepIcons = [];
    for (var step in steps) {
      stepIcons.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              // Display arrow divider between steps
              if (steps.indexOf(step) != 0 &&
                  steps.indexOf(step) != steps.length)
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(Icons.arrow_forward_ios, size: 15),
                ),
              _buildStepIcon(context, step),
            ],
          ),
        ),
      );
    }
    return Wrap(
      children: [
        ...stepIcons,
      ],
    );
  }
}
