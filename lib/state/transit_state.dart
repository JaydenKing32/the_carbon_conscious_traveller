import 'dart:math';

import 'package:the_carbon_conscious_traveller/state/mode_state.dart';

class TransitState extends ModeState {
  List<double> _transitEmissions = [];
  int _minEmissions = 0;
  int _maxEmissions = 0;

  List<double> get transitEmissions => _transitEmissions;
  int get minEmissionValue => _minEmissions;
  int get maxEmissionValue => _maxEmissions;

  void updateTransitEmissions(List<double> emissions) {
    _transitEmissions = emissions;
    _maxEmissions = emissions.reduce(max).round();
    _minEmissions = emissions.reduce(min).round();
    notifyListeners();
  }
}
