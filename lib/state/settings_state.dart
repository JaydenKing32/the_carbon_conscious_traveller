import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';

class SettingsState extends ChangeNotifier {
  bool useSpecifiedCar = false;
  bool useCarForCalculations = false;
  bool useSpecifiedMotorcycle = false;
  bool useMotorcycleForCalculations = false;
  bool useMotorcycleInsteadOfCar = false;

  CarSize selectedCarSize = CarSize.label;
  CarFuelType selectedCarFuelType = CarFuelType.label;
  MotorcycleSize selectedMotorcycleSize = MotorcycleSize.label;

  int leafValue = 100;
  int leafBundleValue = 1000;
  int branchValue = 5000;
  int treeValue = 29000;

  SettingsState() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    useSpecifiedCar = prefs.getBool('useSpecifiedCar') ?? false;
    useCarForCalculations = prefs.getBool('useCarForCalculations') ?? false;
    useSpecifiedMotorcycle = prefs.getBool('useSpecifiedMotorcycle') ?? false;
    useMotorcycleForCalculations =
        prefs.getBool('useMotorcycleForCalculations') ?? false;
    useMotorcycleInsteadOfCar =
        prefs.getBool('useMotorcycleInsteadOfCar') ?? false;

    selectedCarSize = stringToCarSize(
        prefs.getString('selectedCarSize') ?? CarSize.label.toString());
    selectedCarFuelType = stringToCarFuelType(
        prefs.getString('selectedCarFuelType') ?? CarFuelType.label.toString());
    selectedMotorcycleSize = stringToMotorcycleSize(
        prefs.getString('selectedMotorcycleSize') ??
            MotorcycleSize.label.toString());

    leafValue = prefs.getInt('leafValue') ?? 100;
    leafBundleValue = prefs.getInt('leafBundleValue') ?? 1000;
    branchValue = prefs.getInt('branchValue') ?? 5000;
    treeValue = prefs.getInt('treeValue') ?? 29000;

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('useSpecifiedCar', useSpecifiedCar);
    prefs.setBool('useCarForCalculations', useCarForCalculations);
    prefs.setBool('useSpecifiedMotorcycle', useSpecifiedMotorcycle);
    prefs.setBool('useMotorcycleForCalculations', useMotorcycleForCalculations);
    prefs.setBool('useMotorcycleInsteadOfCar', useMotorcycleInsteadOfCar);

    prefs.setString('selectedCarSize', carSizeToString(selectedCarSize));
    prefs.setString(
        'selectedCarFuelType', carFuelTypeToString(selectedCarFuelType));
    prefs.setString(
        'selectedMotorcycleSize', motorcycleSizeToString(selectedMotorcycleSize));

    prefs.setInt('leafValue', leafValue);
    prefs.setInt('leafBundleValue', leafBundleValue);
    prefs.setInt('branchValue', branchValue);
    prefs.setInt('treeValue', treeValue);
  }

  void toggleUseSpecifiedCar(bool value) {
    useSpecifiedCar = value;
    _saveSettings();
    notifyListeners();
  }

  void toggleUseCarForCalculations(bool value) {
    useCarForCalculations = value;
    _saveSettings();
    notifyListeners();
  }

  void toggleUseSpecifiedMotorcycle(bool value) {
    useSpecifiedMotorcycle = value;
    _saveSettings();
    notifyListeners();
  }

  void toggleUseMotorcycleForCalculations(bool value) {
    useMotorcycleForCalculations = value;
    _saveSettings();
    notifyListeners();
  }

  void toggleUseMotorcycleInsteadOfCar(bool value) {
    useMotorcycleInsteadOfCar = value;
    _saveSettings();
    notifyListeners();
  }
}
