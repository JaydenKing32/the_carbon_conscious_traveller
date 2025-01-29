import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/helpers/private_vehicle_emissions_calculator.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_motorcycle_state.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/list_view_motorcycle.dart';

class MotorcyleSettings extends StatefulWidget {
  const MotorcyleSettings({super.key});

  @override
  State<MotorcyleSettings> createState() => _MotorcyleSettingsState();
}

class _MotorcyleSettingsState extends State<MotorcyleSettings> {
  MotorcycleSize? selectedSize;
  late PrivateVehicleEmissionsCalculator emissionCalculator;
  bool _autoCalculated = false; // Flag to prevent repeated auto-calcs

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<Settings>(context);

    // If "Use Specified Motorcycle" is on, automatically calculate
    if (settings.useSpecifiedMotorcycle && !_autoCalculated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final polylinesState = Provider.of<PolylinesState>(context, listen: false);
        final motorcycleState = Provider.of<PrivateMotorcycleState>(context, listen: false);

        // 1) Update MotorcycleState with the user’s saved motorcycle size
        motorcycleState.updateSelectedValue(settings.selectedMotorcycleSize);

        // 2) Initialize a calculator with that size
        final calculator = PrivateVehicleEmissionsCalculator(
          polylinesState: polylinesState,
          vehicleSize: settings.selectedMotorcycleSize,
        );

        // 3) Generate emissions for each route
        final computedEmissions = List<int>.generate(
          polylinesState.result.length,
          (i) => calculator.calculateEmission(i).round(),
        );

        // 4) Populate PrivateMotorcycleState and show the list
        motorcycleState.saveEmissions(computedEmissions);
        motorcycleState.updateVisibility(true);
        motorcycleState.updateMinEmission(calculator.calculateMinEmission().round());
        motorcycleState.updateMaxEmission(calculator.calculateMaxEmission().round());

        setState(() {
          _autoCalculated = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context);
    final polylinesState = Provider.of<PolylinesState>(context);

    // For manual selection, we fall back to `selectedSize ?? label`
    emissionCalculator = PrivateVehicleEmissionsCalculator(
      polylinesState: polylinesState,
      vehicleSize: selectedSize ?? MotorcycleSize.label,
    );

    return Consumer<PrivateMotorcycleState>(
      builder: (context, motorcycleState, child) {
        // If "Use Specified Motorcycle" is on, just display the emissions list
        if (settings.useSpecifiedMotorcycle) {
          return Visibility(
            visible: motorcycleState.isVisible,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  MotorcycleListView(
                    polylinesState: polylinesState,
                    vehicleState: motorcycleState,
                    icon: Icons.sports_motorsports_outlined,
                  ),
                ],
              ),
            ),
          );
        }

        // Otherwise, show the manual “dropdown + calculate” UI
        return Column(
          children: [
            Visibility(
              visible: !motorcycleState.isVisible,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Title(
                      color: Colors.black,
                      child: Text(
                        "Motorcycle",
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        DropdownMenu<MotorcycleSize>(
                          width: 300,
                          initialSelection: motorcycleState.selectedValue,
                          requestFocusOnTap: false,
                          label: const Text('Motorcycle Size'),
                          onSelected: (MotorcycleSize? size) {
                            motorcycleState.updateSelectedValue(
                              size ?? MotorcycleSize.label,
                            );
                            setState(() {
                              selectedSize = motorcycleState.selectedValue;
                            });
                          },
                          dropdownMenuEntries: MotorcycleSize.values
                              .map<DropdownMenuEntry<MotorcycleSize>>(
                                  (MotorcycleSize size) {
                            return DropdownMenuEntry<MotorcycleSize>(
                              value: size,
                              label: size.name,
                              enabled: size != MotorcycleSize.label,
                              style: MenuItemButton.styleFrom(
                                foregroundColor: Colors.black,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      motorcycleState.updateVisibility(true);

                      // Manual calculation logic:
                      final computedEmissions = <int>[];
                      for (int i = 0; i < polylinesState.result.length; i++) {
                        computedEmissions.add(
                          emissionCalculator.calculateEmission(i).round(),
                        );
                      }
                      motorcycleState.saveEmissions(computedEmissions);
                      motorcycleState.updateMinEmission(
                        emissionCalculator.calculateMinEmission().round(),
                      );
                      motorcycleState.updateMaxEmission(
                        emissionCalculator.calculateMaxEmission().round(),
                      );
                    },
                    child: const Text('Calculate Emissions'),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: motorcycleState.isVisible,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    MotorcycleListView(
                      polylinesState: polylinesState,
                      vehicleState: motorcycleState,
                      icon: Icons.sports_motorsports_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
