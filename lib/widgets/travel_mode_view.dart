import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/travel_mode_flying.dart';
import 'package:the_carbon_conscious_traveller/widgets/travel_mode_transit.dart';
import 'package:the_carbon_conscious_traveller/widgets/vehicle_settings_car.dart';
import 'package:the_carbon_conscious_traveller/widgets/vehicle_settings_motorcyle.dart';

class TravelModeView extends StatefulWidget {
  const TravelModeView({super.key});

  @override
  State<TravelModeView> createState() => _TravelModeViewState();
}

class _TravelModeViewState extends State<TravelModeView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PolylinesState>(builder: (context, polylinesState, child) {
      return Builder(builder: (context) {
        if (polylinesState.result.isNotEmpty) {
          if (polylinesState.mode == "motorcycling") {
            return const MotorcyleSettings();
          } else if (polylinesState.mode == "transit") {
            return const Transit();
          } else if (polylinesState.mode == "flying") {
            return const Flying();
          } else if (polylinesState.mode == "driving") {
            return const CarSettings();
          }
        }
        return Center(
          child: Text("Start by entering a start and end location",
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
        );
      });
    });
  }
}
