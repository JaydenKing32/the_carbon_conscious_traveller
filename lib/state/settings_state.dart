import 'package:flutter/material.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';

class SettingsState extends ChangeNotifier {
  // ------------------- Car Settings -------------------
  bool useSpecifiedCar = false;         // "Use specified car"
  bool useCarForCalculations = false;   // "Use car for calculations"
  CarSize selectedCarSize = CarSize.smallCar;
  CarFuelType selectedCarFuelType = CarFuelType.petrol;

  // ---------------- Motorcycle Settings ---------------
  bool useSpecifiedMotorcycle = false;         // "Use specified motorcycle"
  bool useMotorcycleForCalculations = false;   // "Use motorcycle for calculations"
  bool useMotorcycleInsteadOfCar = false;      // "Use specified motorcycle instead..."

  MotorcycleSize selectedMotorcycleSize = MotorcycleSize.small;

  // ------------------- Symbol Values ------------------
  int leafValue = 100;        // Leaf
  int leafBundleValue = 1000; // Leaf bundle
  int branchValue = 5000;     // Branch
  int treeValue = 29000;      // Tree

  // Example toggle methods:
  void toggleUseSpecifiedCar(bool value) {
    useSpecifiedCar = value;
    notifyListeners();
  }

  void toggleUseCarForCalculations(bool value) {
    useCarForCalculations = value;
    notifyListeners();
  }

  void toggleUseSpecifiedMotorcycle(bool value) {
    useSpecifiedMotorcycle = value;
    notifyListeners();
  }

  void toggleUseMotorcycleForCalculations(bool value) {
    useMotorcycleForCalculations = value;
    notifyListeners();
  }

  void toggleUseMotorcycleInsteadOfCar(bool value) {
    useMotorcycleInsteadOfCar = value;
    notifyListeners();
  }
}
