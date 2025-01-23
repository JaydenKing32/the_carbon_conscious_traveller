import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your states, enums, etc.
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settings, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------- Car Settings --------------------
                const SizedBox(height: 16),
                const Text(
                  'Car',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // "Use specified car"
                Row(
                  children: [
                    Checkbox(
                      value: settings.useSpecifiedCar,
                      onChanged: (bool? value) {
                        if (value != null) {
                          settings.toggleUseSpecifiedCar(value);
                        }
                      },
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Use specified car'),
                          Text(
                            'Use the below settings for car mode',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Car size
                ListTile(
                  title: const Text('Car size'),
                  subtitle: DropdownButton<CarSize>(
                    isExpanded: true,
                    value: settings.selectedCarSize,
                    onChanged: settings.useSpecifiedCar
                        ? (CarSize? newVal) {
                            if (newVal != null) {
                              settings.selectedCarSize = newVal;
                              settings.notifyListeners();
                            }
                          }
                        : null, // disable if not "useSpecifiedCar"
                    items: CarSize.values
                        .where((e) => e != CarSize.label)
                        .map<DropdownMenuItem<CarSize>>((CarSize carSize) {
                      return DropdownMenuItem<CarSize>(
                        value: carSize,
                        child: Text(carSize.name),
                      );
                    }).toList(),
                  ),
                ),

                // Car fuel type
                ListTile(
                  title: const Text('Car fuel type'),
                  subtitle: DropdownButton<CarFuelType>(
                    isExpanded: true,
                    value: settings.selectedCarFuelType,
                    onChanged: settings.useSpecifiedCar
                        ? (CarFuelType? newVal) {
                            if (newVal != null) {
                              settings.selectedCarFuelType = newVal;
                              settings.notifyListeners();
                            }
                          }
                        : null, // disable if not "useSpecifiedCar"
                    items: CarFuelType.values
                        .where((e) => e != CarFuelType.label)
                        .map<DropdownMenuItem<CarFuelType>>((CarFuelType cft) {
                      return DropdownMenuItem<CarFuelType>(
                        value: cft,
                        child: Text(cft.name),
                      );
                    }).toList(),
                  ),
                ),

                // "Use car for calculations"
                Row(
                  children: [
                    Checkbox(
                      value: settings.useCarForCalculations,
                      onChanged: (bool? value) {
                        if (value != null) {
                          settings.toggleUseCarForCalculations(value);
                        }
                      },
                    ),
                    const Text('Use car for calculations'),
                  ],
                ),

                const Divider(),

                // ---------------- Motorcycle Settings ----------------
                const Text(
                  'Motorcycle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // "Use specified motorcycle"
                Row(
                  children: [
                    Checkbox(
                      value: settings.useSpecifiedMotorcycle,
                      onChanged: (bool? value) {
                        if (value != null) {
                          settings.toggleUseSpecifiedMotorcycle(value);
                        }
                      },
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Use specified motorcycle'),
                          Text(
                            'Use the below settings for motorcycle mode',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Motorcycle size
                ListTile(
                  title: const Text('Motorcycle size'),
                  subtitle: DropdownButton<MotorcycleSize>(
                    isExpanded: true,
                    value: settings.selectedMotorcycleSize,
                    onChanged: settings.useSpecifiedMotorcycle
                        ? (MotorcycleSize? newVal) {
                            if (newVal != null) {
                              settings.selectedMotorcycleSize = newVal;
                              settings.notifyListeners();
                            }
                          }
                        : null, // disable if not "useSpecifiedMotorcycle"
                    items: MotorcycleSize.values
                        .where((e) => e != MotorcycleSize.label)
                        .map<DropdownMenuItem<MotorcycleSize>>(
                            (MotorcycleSize ms) {
                      return DropdownMenuItem<MotorcycleSize>(
                        value: ms,
                        child: Text(ms.name),
                      );
                    }).toList(),
                  ),
                ),

                // "Use motorcycle for calculations"
                Row(
                  children: [
                    Checkbox(
                      value: settings.useMotorcycleForCalculations,
                      onChanged: (bool? value) {
                        if (value != null) {
                          settings.toggleUseMotorcycleForCalculations(value);
                        }
                      },
                    ),
                    const Text('Use motorcycle for calculations'),
                  ],
                ),

                // "Use specified motorcycle instead.."
                SwitchListTile(
                  title: const Text('Use specified motorcycle instead...'),
                  subtitle: const Text(
                    'If both a motorcycle and car are specified for use in calculations, '
                    'use the specified motorcycle instead of the car, '
                    'otherwise the car will be used',
                    style: TextStyle(color: Colors.grey),
                  ),
                  value: settings.useMotorcycleInsteadOfCar,
                  onChanged: (bool val) {
                    settings.toggleUseMotorcycleInsteadOfCar(val);
                  },
                ),

                const Divider(),

                // ------------------ Symbol Values --------------------
                const Text(
                  'Symbol values',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Set the values (in grams) for displaying symbols that represent carbon-saving',
                  style: TextStyle(color: Colors.grey),
                ),

                // Leaf
                ListTile(
                  leading: const Text('Leaf'),
                  trailing: SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: settings.leafValue.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        settings.leafValue = int.tryParse(val) ?? 100;
                        settings.notifyListeners();
                      },
                    ),
                  ),
                ),
                // Leaf bundle
                ListTile(
                  leading: const Text('Leaf bundle'),
                  trailing: SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: settings.leafBundleValue.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        settings.leafBundleValue = int.tryParse(val) ?? 1000;
                        settings.notifyListeners();
                      },
                    ),
                  ),
                ),
                // Branch
                ListTile(
                  leading: const Text('Branch'),
                  trailing: SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: settings.branchValue.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        settings.branchValue = int.tryParse(val) ?? 5000;
                        settings.notifyListeners();
                      },
                    ),
                  ),
                ),
                // Tree
                ListTile(
                  leading: const Text('Tree'),
                  trailing: SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: settings.treeValue.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        settings.treeValue = int.tryParse(val) ?? 29000;
                        settings.notifyListeners();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
