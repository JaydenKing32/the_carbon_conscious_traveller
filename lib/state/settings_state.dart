import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/data/tree_icon_values.dart';

class Settings extends ChangeNotifier {
  Map<TreeIconType, double> _emissionValues = {};

  bool _useSpecifiedCar = false;
  CarSize _selectedCarSize = CarSize.smallCar;
  CarFuelType _selectedCarFuelType = CarFuelType.petrol;
  bool _useCarForCalculations = false;
  bool x = false;
  bool y = false;
  // Add these getters
  bool get useSpecifiedCar => _useSpecifiedCar;
  CarSize get selectedCarSize => _selectedCarSize;
  CarFuelType get selectedCarFuelType => _selectedCarFuelType;
  bool get useCarForCalculations => _useCarForCalculations;
 
  // Add motorcycle-specific properties
  MotorcycleSize _selectedMotorcycleSize = MotorcycleSize.small;
  bool _useSpecifiedMotorcycle = false;
  bool _useMotorcycleForCalculations = false;

  // Add getters
  MotorcycleSize get selectedMotorcycleSize => _selectedMotorcycleSize;
  bool get useSpecifiedMotorcycle => _useSpecifiedMotorcycle;
  bool get useMotorcycleForCalculations => _useMotorcycleForCalculations;

  bool _enableGeolocationVerification = false;

  bool get enableGeolocationVerification => _enableGeolocationVerification;

  void toggleGeolocationVerification(bool value) {
    _enableGeolocationVerification = value;
    notifyListeners();
  }

  // Add state management methods
  void toggleUseSpecifiedMotorcycle(bool value) async {
    _useSpecifiedMotorcycle = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    _useMotorcycleForCalculations = value;
    notifyListeners();
    final prefs1 = await SharedPreferences.getInstance();
    await prefs1.setBool('useMotorcycleForCalculations', value);
    await prefs.setBool('useSpecifiedMotorcycle', value);
  }

  void toggleUseMotorcycle1(bool value) async {
    y = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useMotorcycleForCalculations1', y);
  }

  void updateMotorcycleSize(MotorcycleSize newValue) async {
    _selectedMotorcycleSize = newValue;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedMotorcycleSize', newValue.toString());
  }

  void toggleUseMotorcycleForCalculations(bool value) async {
    x = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useMotorcycleForCalculations1', x);
  }

  Settings() {
    _initializeDefaults();
    loadPreferences();
  }

  void _initializeDefaults() {
    for (final type in TreeIconType.values) {
      _emissionValues[type] = type.value;
    }
  }

  Map<TreeIconType, double> get emissionValues => _emissionValues;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    _useSpecifiedCar = prefs.getBool('useSpecifiedCar') ?? false;
    _useCarForCalculations = prefs.getBool('useCarForCalculations') ?? false;
    _useSpecifiedMotorcycle = prefs.getBool('useSpecifiedMotorcycle') ?? false;
    _useMotorcycleForCalculations = prefs.getBool('useMotorcycleForCalculations') ?? false;

    for (final type in TreeIconType.values) {
      final key = _getStorageKey(type);
      final savedValue = prefs.getDouble(key);
      if (savedValue != null) {
        _emissionValues[type] = savedValue;
      }
    }
    
     final carSizeString = prefs.getString('selectedCarSize');
    _selectedCarSize = carSizeString != null 
        ? stringToCarSize(carSizeString)
        : CarSize.smallCar;

    final fuelTypeString = prefs.getString('selectedCarFuelType');
    _selectedCarFuelType = fuelTypeString != null
        ? stringToCarFuelType(fuelTypeString)
        : CarFuelType.petrol;
    notifyListeners();

     final motorcycleSizeString = prefs.getString('selectedMotorcycleSize');
    _selectedMotorcycleSize = motorcycleSizeString != null 
        ? stringToMotorcycleSize(motorcycleSizeString)
        : MotorcycleSize.small;
  }

   // Add new methods
  void toggleUseSpecifiedCar(bool value) async {
    _useSpecifiedCar = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSpecifiedCar', value);
  }

  void updateCarSize(CarSize newValue) async {
    _selectedCarSize = newValue;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCarSize', newValue.toString());
  }

  void updateCarFuelType(CarFuelType newValue) async {
    _selectedCarFuelType = newValue;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCarFuelType', newValue.toString());
  }

  void toggleUseCarForCalculations(bool value) async {
    _useCarForCalculations = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useCarForCalculations', value);
  }

  Future<void> updateEmissionValue(TreeIconType type, double value) async {
    _emissionValues[type] = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_getStorageKey(type), value);
  }

  String _getStorageKey(TreeIconType type) => 'emission_${type.name}';
}