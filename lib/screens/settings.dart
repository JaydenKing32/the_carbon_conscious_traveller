import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

                  const SizedBox(height: 20),
                  ...TreeIconType.values.map((type) => _buildEmissionRow(type, settings)),
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
          Text(type.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              type.description,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
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