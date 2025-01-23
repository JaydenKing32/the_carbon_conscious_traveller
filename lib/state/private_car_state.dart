import 'package:flutter/material.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/helpers/tree_icons_calculator.dart';

class PrivateCarState extends ChangeNotifier {
  CarSize? _selectedSize;
  CarFuelType? _selectedFuelType;
  bool? _isVisible;
  int? _minEmission;
  int? _maxEmission;
  List<int> _emissions = [];
  List<String> _treeIcons = [];

  CarSize? get selectedSize => _selectedSize;
  CarFuelType? get selectedFuelType => _selectedFuelType;
  bool get isVisible => _isVisible ?? false;
  int get minEmissionValue => _minEmission ?? 0;
  int get maxEmissionValue => _maxEmission ?? 0;
  List<int> get emissions => _emissions;
  List<String> get treeIcons => _treeIcons;

  void updateSelectedSize(CarSize newValue) {
    _selectedSize = newValue;
    notifyListeners();
  }
  
   void resetEmissions() {
    _emissions = [];
    _minEmission = 0;
    _maxEmission = 0;
    notifyListeners();
  }

  void updateSelectedFuelType(CarFuelType newValue) {
    _selectedFuelType = newValue;
    notifyListeners();
  }

  void updateVisibility(bool isVisible) {
    _isVisible = isVisible;
    notifyListeners();
  }

  void updateMinEmission(int minEmission) {
    _minEmission = minEmission;
    notifyListeners();
  }

  void updateMaxEmission(int maxEmission) {
    _maxEmission = maxEmission;
    notifyListeners();
  }

  void saveEmissions(List<int> emissions) {
    _emissions = emissions;
    notifyListeners();
  }

  void getTreeIcons(index) {
    _treeIcons = upDateTreeIcons(_emissions, index);
  }

  int getEmission(int index) {
    if (index >= 0 && index < _emissions.length) {
      return _emissions[index];
    }
    return 0;
  }
}
