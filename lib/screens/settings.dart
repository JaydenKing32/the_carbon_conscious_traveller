import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            backgroundColor: const Color(0xFF07B36E),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSectionTitle('Car'),

                _buildCheckbox(
                    "Use specified car",
                    settings.useSpecifiedCar,
                    settings.toggleUseSpecifiedCar,
                    "Use the below settings for car mode"),

                _buildDropdown<CarSize>(
                    title: "Car size",
                    value: settings.selectedCarSize,
                    enabled: settings.useSpecifiedCar,
                    onChanged: (newVal) {
                      settings.selectedCarSize = newVal!;
                      settings.notifyListeners();
                    },
                    items: CarSize.values),

                _buildDropdown<CarFuelType>(
                    title: "Car fuel type",
                    value: settings.selectedCarFuelType,
                    enabled: settings.useSpecifiedCar,
                    onChanged: (newVal) {
                      settings.selectedCarFuelType = newVal!;
                      settings.notifyListeners();
                    },
                    items: CarFuelType.values),

                _buildCheckbox(
                    "Use car for calculations",
                    settings.useCarForCalculations,
                    settings.toggleUseCarForCalculations,
                    ""),

                const Divider(),

                _buildSectionTitle('Motorcycle'),

                _buildCheckbox(
                    "Use specified motorcycle",
                    settings.useSpecifiedMotorcycle,
                    settings.toggleUseSpecifiedMotorcycle,
                    "Use the below settings for motorcycle mode"),

                _buildDropdown<MotorcycleSize>(
                    title: "Motorcycle size",
                    value: settings.selectedMotorcycleSize,
                    enabled: settings.useSpecifiedMotorcycle,
                    onChanged: (newVal) {
                      settings.selectedMotorcycleSize = newVal!;
                      settings.notifyListeners();
                    },
                    items: MotorcycleSize.values),

                _buildCheckbox(
                    "Use motorcycle for calculations",
                    settings.useMotorcycleForCalculations,
                    settings.toggleUseMotorcycleForCalculations,
                    ""),

                const Divider(),
                _buildSectionTitle('Symbol Values'),

                _buildNumberField(
                  label: "Leaf",
                  value: settings.leafValue,
                  onChanged: (val) {
                    settings.leafValue = int.tryParse(val) ?? 100;
                    settings.notifyListeners();
                  },
                ),
                _buildNumberField(
                  label: "Leaf Bundle",
                  value: settings.leafBundleValue,
                  onChanged: (val) {
                    settings.leafBundleValue = int.tryParse(val) ?? 1000;
                    settings.notifyListeners();
                  },
                ),
                _buildNumberField(
                  label: "Branch",
                  value: settings.branchValue,
                  onChanged: (val) {
                    settings.branchValue = int.tryParse(val) ?? 5000;
                    settings.notifyListeners();
                  },
                ),
                _buildNumberField(
                  label: "Tree",
                  value: settings.treeValue,
                  onChanged: (val) {
                    settings.treeValue = int.tryParse(val) ?? 29000;
                    settings.notifyListeners();
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _buildCheckbox(String title, bool value, Function(bool) onChanged, String subtitle) {
    return Row(children: [
      Checkbox(value: value, onChanged: (bool? val) => onChanged(val!)),
      Expanded(child: Text(title)),
    ]);
  }

  Widget _buildDropdown<T>({required String title, required T value, required bool enabled, required Function(T?) onChanged, required List<T> items}) {
    return ListTile(
      title: Text(title),
      subtitle: DropdownButton<T>(
        isExpanded: true,
        value: value,
        onChanged: enabled ? onChanged : null,
        items: items.map<DropdownMenuItem<T>>((T item) {
          return DropdownMenuItem<T>(value: item, child: Text(item.toString().split('.').last));
        }).toList(),
      ),
    );
  }

    Widget _buildNumberField({
    required String label,
    required int value,
    required Function(String) onChanged,
  }) {
    return ListTile(
      leading: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: SizedBox(
        width: 80,
        child: TextFormField(
          initialValue: value.toString(),
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          ),
        ),
      ),
    );
  }
}
