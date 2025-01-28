import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_carbon_conscious_traveller/data/tree_icon_values.dart';

class Settings extends ChangeNotifier {
  Map<TreeIconType, double> _emissionValues = {};

  Settings() {
    _initializeDefaults();
  }

  void _initializeDefaults() {
    for (final type in TreeIconType.values) {
      _emissionValues[type] = type.value;
    }
  }

  Map<TreeIconType, double> get emissionValues => _emissionValues;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final type in TreeIconType.values) {
      final key = _getStorageKey(type);
      final savedValue = prefs.getDouble(key);
      if (savedValue != null) {
        _emissionValues[type] = savedValue;
      }
    }
    
    notifyListeners();
  }

  Future<void> updateEmissionValue(TreeIconType type, double value) async {
    _emissionValues[type] = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_getStorageKey(type), value);
  }

  String _getStorageKey(TreeIconType type) => 'emission_${type.name}';
}