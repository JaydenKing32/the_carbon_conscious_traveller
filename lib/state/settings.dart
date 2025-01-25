// settings_state.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';

class SettingsState extends ChangeNotifier {
  // Car Settings
  bool _useSpecifiedCar = false;
  CarSize _selectedCarSize = CarSize.label;
  CarFuelType _selectedCarFuelType = CarFuelType.label;
  bool _useCarForCalculations = false;

  // Motorcycle Settings
  bool _useSpecifiedMotorcycle = false;
  MotorcycleSize _selectedMotorcycleSize = MotorcycleSize.label;
  bool _useMotorcycleForCalculations = false;
  bool _useMotorcycleInsteadOfCar = false;

  // Symbol Values
  int _leafValue = 100;
  int _leafBundleValue = 1000;
  int _branchValue = 5000;
  int _treeValue = 29000;

  // Getters
  bool get useSpecifiedCar => _useSpecifiedCar;
  CarSize get selectedCarSize => _selectedCarSize;
  CarFuelType get selectedCarFuelType => _selectedCarFuelType;
  bool get useCarForCalculations => _useCarForCalculations;

  bool get useSpecifiedMotorcycle => _useSpecifiedMotorcycle;
  MotorcycleSize get selectedMotorcycleSize => _selectedMotorcycleSize;
  bool get useMotorcycleForCalculations => _useMotorcycleForCalculations;
  bool get useMotorcycleInsteadOfCar => _useMotorcycleInsteadOfCar;

  int get leafValue => _leafValue;
  int get leafBundleValue => _leafBundleValue;
  int get branchValue => _branchValue;
  int get treeValue => _treeValue;

  // Setters with notifyListeners and persistence
  void toggleUseSpecifiedCar(bool value) {
    _useSpecifiedCar = value;
    _saveBool('useSpecifiedCar', value);
    notifyListeners();
  }

  set selectedCarSize(CarSize value) {
    _selectedCarSize = value;
    _saveString('selectedCarSize', carSizeToString(value));
    notifyListeners();
  }

  set selectedCarFuelType(CarFuelType value) {
    _selectedCarFuelType = value;
    _saveString('selectedCarFuelType', value.toString());
    notifyListeners();
  }

  void toggleUseCarForCalculations(bool value) {
    _useCarForCalculations = value;
    _saveBool('useCarForCalculations', value);
    notifyListeners();
  }

  void toggleUseSpecifiedMotorcycle(bool value) {
    _useSpecifiedMotorcycle = value;
    _saveBool('useSpecifiedMotorcycle', value);
    notifyListeners();
  }

  set selectedMotorcycleSize(MotorcycleSize value) {
    _selectedMotorcycleSize = value;
    _saveString('selectedMotorcycleSize', value.toString());
    notifyListeners();
  }

  void toggleUseMotorcycleForCalculations(bool value) {
    _useMotorcycleForCalculations = value;
    _saveBool('useMotorcycleForCalculations', value);
    notifyListeners();
  }

  void toggleUseMotorcycleInsteadOfCar(bool value) {
    _useMotorcycleInsteadOfCar = value;
    _saveBool('useMotorcycleInsteadOfCar', value);
    notifyListeners();
  }

  set leafValue(int value) {
    _leafValue = value;
    _saveInt('leafValue', value);
    notifyListeners();
  }

  set leafBundleValue(int value) {
    _leafBundleValue = value;
    _saveInt('leafBundleValue', value);
    notifyListeners();
  }

  set branchValue(int value) {
    _branchValue = value;
    _saveInt('branchValue', value);
    notifyListeners();
  }

  set treeValue(int value) {
    _treeValue = value;
    _saveInt('treeValue', value);
    notifyListeners();
  }

  // Persistence Methods
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _useSpecifiedCar = prefs.getBool('useSpecifiedCar') ?? false;
    _selectedCarSize = stringToCarSize(prefs.getString('selectedCarSize') ?? CarSize.label.toString());
    _selectedCarFuelType = stringToCarFuelType(prefs.getString('selectedCarFuelType') ?? CarFuelType.label.toString());
    _useCarForCalculations = prefs.getBool('useCarForCalculations') ?? false;

    _useSpecifiedMotorcycle = prefs.getBool('useSpecifiedMotorcycle') ?? false;
    _selectedMotorcycleSize = stringToMotorcycleSize(prefs.getString('selectedMotorcycleSize') ?? MotorcycleSize.label.toString());
    _useMotorcycleForCalculations = prefs.getBool('useMotorcycleForCalculations') ?? false;
    _useMotorcycleInsteadOfCar = prefs.getBool('useMotorcycleInsteadOfCar') ?? false;

    _leafValue = prefs.getInt('leafValue') ?? 100;
    _leafBundleValue = prefs.getInt('leafBundleValue') ?? 1000;
    _branchValue = prefs.getInt('branchValue') ?? 5000;
    _treeValue = prefs.getInt('treeValue') ?? 29000;

    notifyListeners();
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  // Helper conversion methods for enums
  CarSize stringToCarSize(String carSizeStr) {
    return CarSize.values.firstWhere(
      (e) => e.toString() == carSizeStr,
      orElse: () => CarSize.label,
    );
  }

  CarFuelType stringToCarFuelType(String carFuelTypeStr) {
    return CarFuelType.values.firstWhere(
      (e) => e.toString() == carFuelTypeStr,
      orElse: () => CarFuelType.label,
    );
  }

  MotorcycleSize stringToMotorcycleSize(String motorcycleSizeStr) {
    return MotorcycleSize.values.firstWhere(
      (e) => e.toString() == motorcycleSizeStr,
      orElse: () => MotorcycleSize.label,
    );
  }
}
