import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/helpers/tree_icons_calculator.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/travel_mode_buttons.dart';

abstract class ModeState extends ChangeNotifier {
  bool? _isVisible;
  int? _minEmission;
  int? _maxEmission;
  List<int> _emissions = [];
  List<String> _treeIcons = [];
  final HashMap<String, double> _maxConfiguredEmissions = HashMap.from({driving: 0.0, motorcycling: 0.0});

  bool get isVisible => _isVisible ?? false;
  int get minEmissionValue => _minEmission ?? 0;
  int get maxEmissionValue => _maxEmission ?? 0;
  List<int> get emissions => _emissions;
  List<String> get treeIcons => _treeIcons;

  void resetEmissions() {
    _emissions = [];
    _minEmission = 0;
    _maxEmission = 0;
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

  void updateMaxConfiguredEmissions(String mode, double emission) {
    _maxConfiguredEmissions[mode] = emission;
    notifyListeners();
  }

  void saveEmissions(List<int> emissions) {
    _emissions = emissions;
    notifyListeners();
  }

  void getTreeIcons(int index, BuildContext context) {
    final settings = Provider.of<Settings>(context, listen: false);
    double maxConfiguredEmission = 0;
    if (settings.useCarForCalculations && !settings.useMotorcycleInsteadOfCar) {
      maxConfiguredEmission = _maxConfiguredEmissions[driving]!;
    } else if (settings.useMotorcycleForCalculations && (settings.useMotorcycleInsteadOfCar || !settings.useCarForCalculations)) {
      maxConfiguredEmission = _maxConfiguredEmissions[motorcycling]!;
    }
    _treeIcons = upDateTreeIcons(_emissions, maxConfiguredEmission, index, settings);
    notifyListeners();
  }

  int getEmission(int index) {
    if (index >= 0 && index < _emissions.length) {
      return _emissions[index];
    }
    return 0;
  }
}
