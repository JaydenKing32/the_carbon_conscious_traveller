import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/state/mode_state.dart';

class PrivateCarState extends ModeState {
  CarSize? _selectedSize;
  CarFuelType? _selectedFuelType;
  CarSize? get selectedSize => _selectedSize;
  CarFuelType? get selectedFuelType => _selectedFuelType;

  void updateSelectedSize(CarSize newValue) {
    _selectedSize = newValue;
    notifyListeners();
  }

  void updateSelectedFuelType(CarFuelType newValue) {
    _selectedFuelType = newValue;
    notifyListeners();
  }
}
