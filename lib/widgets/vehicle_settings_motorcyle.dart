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
  bool isVisible = false;
  late PrivateVehicleEmissionsCalculator emissionCalculator;
  List<int> emissions = [];
  List<String> treeIconName = [];
  bool _isBtnDisabled = false;
  bool _autoCalculated = false;
  VoidCallback? _polylinesListener;

  @override
  void initState() {
    _isBtnDisabled = true;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<Settings>(context);
    final polylinesState = Provider.of<PolylinesState>(context, listen: false);

    if (settings.useMotorcycleForCalculations) {
      // Remove existing listener to avoid duplicates
      if (_polylinesListener != null) {
        polylinesState.removeListener(_polylinesListener!);
        _polylinesListener = null;
      }

      _polylinesListener = () {
        if (polylinesState.result.isNotEmpty) {
          _performAutoCalculation();
          // Remove listener after successful calculation
          polylinesState.removeListener(_polylinesListener!);
          _polylinesListener = null;
        }
      };

      if (polylinesState.result.isNotEmpty) {
        _performAutoCalculation();
      } else {
        polylinesState.addListener(_polylinesListener!);
      }
    }
  }

  void _performAutoCalculation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<Settings>(context, listen: false);
      final motorcycleState = Provider.of<PrivateMotorcycleState>(context, listen: false);
      final polylinesState = Provider.of<PolylinesState>(context, listen: false);

      motorcycleState.updateSelectedValue(settings.selectedMotorcycleSize);
      
      final calculator = PrivateVehicleEmissionsCalculator(
        polylinesState: polylinesState,
        vehicleSize: settings.selectedMotorcycleSize,
      );
      
      final emissions = List<int>.generate(
        polylinesState.result.length,
        (i) => calculator.calculateEmission(i).round()
      );
      
      motorcycleState.saveEmissions(emissions);
      motorcycleState.updateVisibility(true);
      motorcycleState.updateMinEmission(calculator.calculateMinEmission().round());
      motorcycleState.updateMaxEmission(calculator.calculateMaxEmission().round());

      setState(() { _autoCalculated = true; });
    });
  }

  @override
  void dispose() {
    final polylinesState = Provider.of<PolylinesState>(context, listen: false);
    if (_polylinesListener != null) {
      polylinesState.removeListener(_polylinesListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PolylinesState polylinesState = Provider.of<PolylinesState>(context);
    emissionCalculator = PrivateVehicleEmissionsCalculator(
      polylinesState: polylinesState,
      vehicleSize: selectedSize ?? MotorcycleSize.label,
    );

    return Consumer<PrivateMotorcycleState>(
      builder: (context, motorcycleState, child) {
        void changeVisibility(bool isVisible) {
          motorcycleState.updateVisibility(isVisible);
        }

        int minEmission = 0;
        int maxEmission = 0;

        void getMinMaxEmissions() {
          minEmission = emissionCalculator.calculateMinEmission().round();
          motorcycleState.updateMinEmission(minEmission);
          maxEmission = emissionCalculator.calculateMaxEmission().round();
          motorcycleState.updateMaxEmission(maxEmission);
        }

        void getEmissions() {
          for (int i = 0; i < polylinesState.result.length; i++) {
            emissions.add(emissionCalculator.calculateEmission(i).round());
          }
          motorcycleState.saveEmissions(emissions);
        }

        final settings = Provider.of<Settings>(context);

        emissionCalculator = PrivateVehicleEmissionsCalculator(
        polylinesState: polylinesState,
        vehicleSize: settings.useMotorcycleForCalculations
            ? settings.selectedMotorcycleSize
            : selectedSize ?? MotorcycleSize.label,
      );

        if (settings.useSpecifiedCar) {
          return Visibility(
            visible: motorcycleState.isVisible,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  MotorcycleListView(
                    polylinesState: Provider.of<PolylinesState>(context),
                    vehicleState: motorcycleState,
                    icon: Icons.directions_car_outlined,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Visibility(
              visible: !motorcycleState.isVisible,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
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
                                size ?? MotorcycleSize.label);
                            setState(() {
                              selectedSize = motorcycleState.selectedValue;
                              _isBtnDisabled = false;
                            });
                          },
                          dropdownMenuEntries: MotorcycleSize.values
                              .map<DropdownMenuEntry<MotorcycleSize>>(
                                  (MotorcycleSize size) {
                            return DropdownMenuEntry<MotorcycleSize>(
                              value: size,
                              label: size.name,
                              enabled: size.name != MotorcycleSize.label.name,
                              style: MenuItemButton.styleFrom(
                                  foregroundColor: Colors.black),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: _isBtnDisabled
                        ? null
                        : () {
                            changeVisibility(true);
                            getEmissions();
                            getMinMaxEmissions();
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
