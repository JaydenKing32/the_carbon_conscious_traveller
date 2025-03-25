import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/helpers/private_car_emissions_calculator.dart';
import 'package:the_carbon_conscious_traveller/state/private_car_state.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/list_view_car.dart';
import 'package:the_carbon_conscious_traveller/widgets/travel_mode_buttons.dart';

class CarSettings extends StatefulWidget {
  const CarSettings({super.key});

  @override
  State<CarSettings> createState() => _CarSettingsState();
}

class _CarSettingsState extends State<CarSettings> {
  CarSize? selectedSize;
  CarFuelType? selectedFuelType;
  int? currCarSizeIdx;
  late List<CarFuelType> availableFuelTypes = [];
  late PrivateCarEmissionsCalculator emissionCalculator;
  List<String> treeIcons = [];
  bool _isBtnDisabled = false;
  bool _isDropDownEnabled = true;

  @override
  void initState() {
    _isBtnDisabled = true;
    _isDropDownEnabled = false;
    super.initState();
  }

  bool _autoCalculated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<Settings>(context);

    if (settings.useSpecifiedCar && !_autoCalculated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final carState = Provider.of<PrivateCarState>(context, listen: false);
        final polylinesState = Provider.of<PolylinesState>(context, listen: false);

        // Set selections from settings
        carState.updateSelectedSize(settings.selectedCarSize);
        carState.updateSelectedFuelType(settings.selectedCarFuelType);

        // Initialize calculator with settings
        final calculator = PrivateCarEmissionsCalculator(
          polylinesState: polylinesState,
          settings: settings,
          routeCarSize: selectedSize ?? CarSize.label,
          routeCarFuel: selectedFuelType ?? CarFuelType.label,
        );

        // Calculate emissions
        final emissions = List<int>.generate(polylinesState.result.length, (i) => calculator.calculateEmissions(i, settings.selectedCarSize, settings.selectedCarFuelType).round());

        // Update state
        carState.saveEmissions(emissions);
        carState.updateVisibility(true);
        carState.updateMinEmission(calculator.calculateMinEmission().round());
        carState.updateMaxEmission(calculator.calculateMaxEmission().round());
        double configuredFactor = carValuesMatrix[settings.selectedCarSize.index][settings.selectedCarFuelType.index];
        carState.updateMaxConfiguredEmissions(driving, configuredFactor * polylinesState.distances.reduce(max));

        setState(() {
          _autoCalculated = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context);
    PolylinesState polylinesState = Provider.of<PolylinesState>(context);

    // Initialize emission calculator based on settings
    if (settings.useSpecifiedCar) {
      emissionCalculator = PrivateCarEmissionsCalculator(
        routeCarSize: selectedSize ?? CarSize.label,
        routeCarFuel: selectedFuelType ?? CarFuelType.label,
        polylinesState: polylinesState,
        settings: settings,
      );
    } else {
      emissionCalculator = PrivateCarEmissionsCalculator(
        polylinesState: polylinesState,
        routeCarSize: selectedSize ?? CarSize.label,
        routeCarFuel: selectedFuelType ?? CarFuelType.label,
        settings: settings,
      );
    }

    return Consumer<PrivateCarState>(
      builder: (context, carState, child) {
        // Sync carState with settings when 'useSpecifiedCar' is enabled
        void setFuelTypeItems(int selectedSizeIndex) {
          List<CarFuelType> availOptions = [];
          availableFuelTypes = [];
          for (double matrixValue in carValuesMatrix[selectedSizeIndex]) {
            int index = carValuesMatrix[selectedSizeIndex].indexWhere((value) => value == matrixValue);
            if (matrixValue != 0) {
              availOptions.add(CarFuelType.values[index]);
            }
          }
          availableFuelTypes.addAll(availOptions);
        }

        if (settings.useSpecifiedCar) {
          return Visibility(
            visible: carState.isVisible,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  CarListView(polylinesState: Provider.of<PolylinesState>(context), vehicleState: carState, icon: Icons.directions_car_outlined, settings: settings),
                ],
              ),
            ),
          );
        }
        void getMinMaxEmissions() {
          final minEmission = emissionCalculator.calculateMinEmission().round();
          carState.updateMinEmission(minEmission);
          final maxEmission = emissionCalculator.calculateMaxEmission().round();
          carState.updateMaxEmission(maxEmission);
        }

        void getCarEmissions() {
          List<int> emissions = [];
          for (int i = 0; i < polylinesState.result.length; i++) {
            emissions.add(emissionCalculator.calculateEmissions(i, selectedSize!, selectedFuelType!).round());
          }
          carState.saveEmissions(emissions);
        }

        void changeVisibility(bool isVisible) {
          carState.updateVisibility(isVisible);
        }

        return Column(
          children: <Widget>[
            Visibility(
              visible: !carState.isVisible,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Title(
                      color: Colors.black,
                      child: Text(
                        "Car",
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        DropdownMenu<CarSize>(
                          enabled: !settings.useSpecifiedCar,
                          width: 300,
                          initialSelection: settings.useSpecifiedCar ? settings.selectedCarSize : carState.selectedSize,
                          requestFocusOnTap: false,
                          label: const Text('Car Size'),
                          onSelected: (CarSize? size) {
                            carState.updateSelectedSize(size ?? CarSize.label);
                            if (currCarSizeIdx != size!.index) {
                              setFuelTypeItems(size.index);
                            }
                            setState(() {
                              selectedSize = carState.selectedSize;
                              _isDropDownEnabled = true;
                            });
                          },
                          dropdownMenuEntries: CarSize.values.map<DropdownMenuEntry<CarSize>>((CarSize size) {
                            return DropdownMenuEntry<CarSize>(
                              value: size,
                              label: size.name,
                              enabled: size.name != 'Select',
                              style: MenuItemButton.styleFrom(foregroundColor: Colors.black),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        DropdownMenu<CarFuelType>(
                          enabled: !settings.useSpecifiedCar && _isDropDownEnabled,
                          width: 300,
                          initialSelection: settings.useSpecifiedCar ? settings.selectedCarFuelType : carState.selectedFuelType,
                          requestFocusOnTap: false,
                          label: const Text('Fuel Type'),
                          onSelected: (CarFuelType? fuelType) {
                            carState.updateSelectedFuelType(fuelType ?? CarFuelType.label);
                            setState(() {
                              selectedFuelType = fuelType;
                              _isBtnDisabled = false;
                            });
                          },
                          dropdownMenuEntries: availableFuelTypes.map<DropdownMenuEntry<CarFuelType>>((CarFuelType type) {
                            return DropdownMenuEntry<CarFuelType>(
                              value: type,
                              label: type.name,
                              enabled: type.name != 'Select',
                              style: MenuItemButton.styleFrom(foregroundColor: Colors.black),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: (settings.useSpecifiedCar || (!_isBtnDisabled && selectedSize != null && selectedFuelType != null))
                        ? () {
                            if (settings.useSpecifiedCar) {
                              selectedSize = settings.selectedCarSize;
                              selectedFuelType = settings.selectedCarFuelType;
                            }
                            if (selectedSize == null || selectedFuelType == null) {
                              return;
                            }
                            changeVisibility(true);
                            getMinMaxEmissions();
                            getCarEmissions();
                          }
                        : null,
                    child: const Text("Calculate Emissions"),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: carState.isVisible,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    CarListView(
                      polylinesState: polylinesState,
                      vehicleState: carState,
                      icon: Icons.directions_car_outlined,
                      settings: settings,
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
