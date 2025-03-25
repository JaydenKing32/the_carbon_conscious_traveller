import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/state/mode_state.dart';

class PrivateMotorcycleState extends ModeState {
  MotorcycleSize? _selectedValue;
  MotorcycleSize? get selectedValue => _selectedValue;

  void updateSelectedValue(MotorcycleSize newValue) {
    _selectedValue = newValue;
    notifyListeners();
  }
}
