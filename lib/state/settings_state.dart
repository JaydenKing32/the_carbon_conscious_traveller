// lib/state/settings_state.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_carbon_conscious_traveller/data/tree_icon_values.dart';
import '../data/calculation_values.dart'; // Adjust the import path as necessary

class SettingsState extends ChangeNotifier {
  // =================== Car Settings ===================
  bool _useSpecifiedCar = false;
  CarSize _selectedCarSize = CarSize.label;
  CarFuelType _selectedCarFuelType = CarFuelType.label;
  bool _useCarForCalculations = false;

  bool get useSpecifiedCar => _useSpecifiedCar;
  CarSize get selectedCarSize => _selectedCarSize;
  CarFuelType get selectedCarFuelType => _selectedCarFuelType;
  bool get useCarForCalculations => _useCarForCalculations;

  // ================== Motorcycle Settings ==================
  bool _useSpecifiedMotorcycle = false;
  MotorcycleSize _selectedMotorcycleSize = MotorcycleSize.label;
  bool _useMotorcycleForCalculations = false;

  bool get useSpecifiedMotorcycle => _useSpecifiedMotorcycle;
  MotorcycleSize get selectedMotorcycleSize => _selectedMotorcycleSize;
  bool get useMotorcycleForCalculations => _useMotorcycleForCalculations;

  // ================== Tree Settings ==================
  // Map to hold emission values for each TreeIconType
  Map<TreeIconType, double> _treeEmissionValues = {};

  Map<TreeIconType, double> get treeEmissionValues => _treeEmissionValues;

  SettingsState() {
    _loadSettings();
  }

  // Load settings from shared_preferences
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load Car Settings
    _useSpecifiedCar = prefs.getBool('useSpecifiedCar') ?? false;
    String carSizeStr = prefs.getString('selectedCarSize') ?? 'label';
    String fuelTypeStr = prefs.getString('selectedCarFuelType') ?? 'label';
    _useCarForCalculations = prefs.getBool('useCarForCalculations') ?? false;

    _selectedCarSize = stringToCarSize(carSizeStr);
    _selectedCarFuelType = stringToCarFuelType(fuelTypeStr);

    // Load Motorcycle Settings
    _useSpecifiedMotorcycle = prefs.getBool('useSpecifiedMotorcycle') ?? false;
    String motorcycleSizeStr = prefs.getString('selectedMotorcycleSize') ?? 'label';
    _useMotorcycleForCalculations = prefs.getBool('useMotorcycleForCalculations') ?? false;

    _selectedMotorcycleSize = stringToMotorcycleSize(motorcycleSizeStr);

    // Load Tree Emission Values
    for (TreeIconType type in TreeIconType.values) {
      String key = 'treeEmission_${type.toString()}';
      _treeEmissionValues[type] = prefs.getDouble(key) ?? type.hashCode.toDouble();
    }

    notifyListeners();
  }

  // =================== Car Settings Methods ===================

  Future<void> toggleUseSpecifiedCar(bool value) async {
    _useSpecifiedCar = value;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSpecifiedCar', value);
  }

  Future<void> updateCarSize(CarSize size) async {
    _selectedCarSize = size;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCarSize', carSizeToString(size));
  }

  Future<void> updateCarFuelType(CarFuelType fuelType) async {
    _selectedCarFuelType = fuelType;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCarFuelType', carFuelTypeToString(fuelType));
  }

  Future<void> toggleUseCarForCalculations(bool value) async {
    _useCarForCalculations = value;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useCarForCalculations', value);
  }

  // ================== Motorcycle Settings Methods ==================

  Future<void> toggleUseSpecifiedMotorcycle(bool value) async {
    _useSpecifiedMotorcycle = value;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSpecifiedMotorcycle', value);
  }

  Future<void> updateMotorcycleSize(MotorcycleSize size) async {
    _selectedMotorcycleSize = size;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedMotorcycleSize', motorcycleSizeToString(size));
  }

  Future<void> toggleUseMotorcycleForCalculations(bool value) async {
    _useMotorcycleForCalculations = value;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useMotorcycleForCalculations', value);
  }

  // ================== Tree Settings Methods ==================

  Future<void> updateTreeEmission(TreeIconType type, double value) async {
    _treeEmissionValues[type] = value;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('treeEmission_${type.toString()}', value);
  }

  // =================== Helper Functions ===================

  // CarSize
  CarSize stringToCarSize(String sizeStr) {
    return CarSize.values.firstWhere(
        (e) => e.toString().split('.').last == sizeStr,
        orElse: () => CarSize.label);
  }

  String carSizeToString(CarSize size) {
    return size.toString().split('.').last;
  }

  // CarFuelType
  CarFuelType stringToCarFuelType(String fuelStr) {
    return CarFuelType.values.firstWhere(
        (e) => e.toString().split('.').last == fuelStr,
        orElse: () => CarFuelType.label);
  }

  String carFuelTypeToString(CarFuelType fuel) {
    return fuel.toString().split('.').last;
  }

  // MotorcycleSize
  MotorcycleSize stringToMotorcycleSize(String sizeStr) {
    return MotorcycleSize.values.firstWhere(
        (e) => e.toString().split('.').last == sizeStr,
        orElse: () => MotorcycleSize.label);
  }

  String motorcycleSizeToString(MotorcycleSize size) {
    return size.toString().split('.').last;
  }
}
