// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/data/tree_icon_values.dart';
import '../state/settings_state.dart';
import '../data/calculation_values.dart'; // Adjust the import path as necessary
// Helper method to get description based on TreeIconType
    String _getTreeIconDescription(TreeIconType type) {
      switch (type) {
        case TreeIconType.defaultOneLeafC02Gram:
          return "One Leaf";
        case TreeIconType.defaultFourLeavesC02Gram:
          return "Four Leaves";
        case TreeIconType.defaultTreeBranchC02Gram:
          return "Tree Branch";
        case TreeIconType.defaultTreeCo2Gram:
          return "Full Tree";
        default:
          return "";
      }
    }
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color.fromARGB(255, 7, 179, 110),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<SettingsState>(
          builder: (context, settings, child) {
            return ListView(
              children: [
                // ================== Car Settings ==================
                const Text(
                  'Car Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Use Specified Car Switch
                SwitchListTile(
                  title: const Text('Use Specified Car'),
                  subtitle: const Text('Automatically use your specified car for routes'),
                  value: settings.useSpecifiedCar,
                  onChanged: (bool value) {
                    settings.toggleUseSpecifiedCar(value);
                  },
                ),
                const SizedBox(height: 16),

                // Car Size Dropdown (Visible when Use Specified Car is enabled)
                if (settings.useSpecifiedCar) ...[
                  DropdownButtonFormField<CarSize>(
                    decoration: const InputDecoration(
                      labelText: 'Car Size',
                      border: OutlineInputBorder(),
                    ),
                    value: settings.selectedCarSize,
                    items: CarSize.values.map((CarSize size) {
                      return DropdownMenuItem<CarSize>(
                        value: size,
                        child: Text(
                          size == CarSize.label ? 'Select Car Size' : size.name,
                        ),
                      );
                    }).toList(),
                    onChanged: (CarSize? newValue) {
                      if (newValue != null && newValue != CarSize.label) {
                        settings.updateCarSize(newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Car Fuel Type Dropdown
                  DropdownButtonFormField<CarFuelType>(
                    decoration: const InputDecoration(
                      labelText: 'Fuel Type',
                      border: OutlineInputBorder(),
                    ),
                    value: settings.selectedCarFuelType,
                    items: CarFuelType.values.map((CarFuelType fuel) {
                      return DropdownMenuItem<CarFuelType>(
                        value: fuel,
                        child: Text(
                          fuel == CarFuelType.label ? 'Select Fuel Type' : fuel.name,
                        ),
                      );
                    }).toList(),
                    onChanged: (CarFuelType? newValue) {
                      if (newValue != null && newValue != CarFuelType.label) {
                        settings.updateCarFuelType(newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Use Car for Calculations Switch
                SwitchListTile(
                  title: const Text('Use Car for Calculations'),
                  subtitle: const Text('Use your specified car for emissions calculations and comparisons'),
                  value: settings.useCarForCalculations,
                  onChanged: (bool value) {
                    settings.toggleUseCarForCalculations(value);
                  },
                ),
                const SizedBox(height: 24),

                // ================== Motorcycle Settings ==================
                const Text(
                  'Motorcycle Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Use Specified Motorcycle Switch
                SwitchListTile(
                  title: const Text('Use Specified Motorcycle'),
                  subtitle: const Text('Automatically use your specified motorcycle for routes'),
                  value: settings.useSpecifiedMotorcycle,
                  onChanged: (bool value) {
                    settings.toggleUseSpecifiedMotorcycle(value);
                  },
                ),
                const SizedBox(height: 16),

                // Motorcycle Size Dropdown (Visible when Use Specified Motorcycle is enabled)
                if (settings.useSpecifiedMotorcycle) ...[
                  DropdownButtonFormField<MotorcycleSize>(
                    decoration: const InputDecoration(
                      labelText: 'Motorcycle Size',
                      border: OutlineInputBorder(),
                    ),
                    value: settings.selectedMotorcycleSize,
                    items: MotorcycleSize.values.map((MotorcycleSize size) {
                      return DropdownMenuItem<MotorcycleSize>(
                        value: size,
                        child: Text(
                          size == MotorcycleSize.label ? 'Select Motorcycle Size' : size.name,
                        ),
                      );
                    }).toList(),
                    onChanged: (MotorcycleSize? newValue) {
                      if (newValue != null && newValue != MotorcycleSize.label) {
                        settings.updateMotorcycleSize(newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // No Motorcycle Fuel Type Dropdown since motorcycles don't have fuel types
                ],

                // Use Motorcycle for Calculations Switch
                SwitchListTile(
                  title: const Text('Use Motorcycle for Calculations'),
                  subtitle: const Text('Use your specified motorcycle for emissions calculations and comparisons'),
                  value: settings.useMotorcycleForCalculations,
                  onChanged: (bool value) {
                    settings.toggleUseMotorcycleForCalculations(value);
                  },
                ),
                const SizedBox(height: 24),

                // ================== Tree Emission Settings ==================
                const Text(
                  'Tree Emission Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Informational Note
                const Text(
                  'Modify the emission values for each tree type as needed. These values represent the grams of CO2 saved.',
                  style: TextStyle(color: Colors.grey),
                ),
                
                const SizedBox(height: 10),

                // Emission Values for Each TreeIconType
                ...TreeIconType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        // Display Tree Emoji
                        Text(
                          type.emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(width: 16),
                        // Display Tree Icon Description
                        Expanded(
                          child: Text(
                            _getTreeIconDescription(type),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Input Field for Emission Value
                        Container(
                          width: 120,
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Emission (g CO2)',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: settings.treeEmissionValues[type]?.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              double parsedValue = double.tryParse(value) ?? type.hashCode.toDouble();
                              settings.updateTreeEmission(type, parsedValue);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                
              ],
            );
          },
        ),
      ),
    );

  }
}
