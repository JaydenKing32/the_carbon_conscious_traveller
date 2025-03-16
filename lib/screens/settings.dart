import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/data/tree_icon_values.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color.fromARGB(255, 7, 179, 110),
      ),
      body: settings.emissionValues.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Geolocation Settings',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text('Enable Geolocation Verification', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04)),
                            subtitle: Text('Verify your trips with geolocation service', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035)),
                            value: settings.enableGeolocationVerification,
                            onChanged: (bool value) {
                              settings.toggleGeolocationVerification(value);
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Car Settings',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text('Use Specified Car', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04)),
                            subtitle: Text('Automatically use your specified car for routes', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035)),
                            value: settings.useSpecifiedCar,
                            onChanged: (bool value) {
                              settings.toggleUseSpecifiedCar(value);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Car Size Dropdown
                          DropdownButtonFormField<CarSize>(
                            decoration: InputDecoration(
                              labelText: 'Car Size',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[400]!),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            value: settings.selectedCarSize,
                            items: CarSize.values.map((CarSize size) {
                              final isSelectOption = "Select" == size.name;

                              return DropdownMenuItem<CarSize>(
                                value: size,
                                enabled: !isSelectOption,
                                child: Text(
                                  size.name,
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.04,
                                    fontWeight: FontWeight.w500,
                                    color: isSelectOption ? Colors.grey : Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (CarSize? newValue) {
                              if (newValue != null && newValue.name != "Select") {
                                settings.updateCarSize(newValue);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Car Fuel Type Dropdown
                          DropdownButtonFormField<CarFuelType>(
                            decoration: InputDecoration(
                              labelText: 'Fuel Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[400]!),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            value: settings.selectedCarFuelType,
                            items: CarFuelType.values.map((CarFuelType fuel) {
                              final isSelectOption = "Select" == fuel.name;
                              return DropdownMenuItem<CarFuelType>(
                                value: fuel,
                                enabled: !isSelectOption,
                                child: Text(
                                  fuel.name,
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.04,
                                    fontWeight: FontWeight.w500,
                                    color: isSelectOption ? Colors.grey : Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (CarFuelType? newValue) {
                              if (newValue != null && newValue.name != "Select") {
                                settings.updateCarFuelType(newValue);
                              }
                            },
                          ),

                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SwitchListTile(
                              title: Text(
                                'Use Car for Calculations',
                                style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
                              ),
                              subtitle: Text(
                                'Use your specified car for emissions calculations',
                                style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),
                              ),
                              value: settings.useCarForCalculations,
                              onChanged: (bool value) {
                                settings.toggleUseCarForCalculations(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Motorcycle Settings',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text(
                              'Use Specified Motorcycle',
                              style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
                            ),
                            subtitle: Text('Automatically use your specified motorcycle for routes', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035)),
                            value: settings.useSpecifiedMotorcycle,
                            onChanged: (bool value) => settings.toggleUseSpecifiedMotorcycle(value),
                          ),
                          const SizedBox(height: 16),

                          // Motorcycle Size Dropdown
                          DropdownButtonFormField<MotorcycleSize>(
                            decoration: InputDecoration(
                              labelText: 'Motorcycle Size',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[400]!),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            value: settings.selectedMotorcycleSize,
                            items: MotorcycleSize.values.map((MotorcycleSize size) {
                              final isSelectOption = "Size" == size.name;

                              return DropdownMenuItem<MotorcycleSize>(
                                value: size,
                                enabled: !isSelectOption,
                                child: Text(
                                  size.name,
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.04,
                                    fontWeight: FontWeight.w500,
                                    color: isSelectOption ? Colors.grey : Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (MotorcycleSize? newValue) {
                              if (newValue != null) {
                                settings.updateMotorcycleSize(newValue);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          SwitchListTile(
                            title: Text(
                              'Use Motorcycle for Calculations',
                              style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
                            ),
                            subtitle: Text(
                              'Use your specified motorcycle for emissions calculations',
                              style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035, color: Colors.grey),
                            ),
                            value: settings.x,
                            onChanged: (bool value) => settings.toggleUseMotorcycleForCalculations(value),
                          ),

                          SwitchListTile(
                            title: Text(
                              'Use Motorcycle instead of Car',
                              style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04), // Responsive title size
                            ),
                            subtitle: Text(
                              'If both a motorcycle and car are specified for use in calculations, use the specified motorcycle instead of the car, otherwise the car will be used',
                              style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035, color: Colors.grey), // Responsive subtitle
                            ),
                            value: settings.y,
                            onChanged: (bool value) => settings.toggleUseMotorcycle1(value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tree Emission Settings',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Modify the emission values for each tree type as needed. These values represent the grams of CO₂ saved.',
                            style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ...TreeIconType.values.map((type) => _buildEmissionRow(type, settings)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmissionRow(TreeIconType type, Settings settings) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Text(type.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              type.description,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Emission (g CO₂)',
                border: OutlineInputBorder(),
              ),
              initialValue: settings.emissionValues[type]?.toStringAsFixed(0),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final parsedValue = double.tryParse(value) ?? type.value;
                settings.updateEmissionValue(type, parsedValue);
              },
            ),
          ),
        ],
      ),
    );
  }
}
