import 'dart:math';
import 'package:the_carbon_conscious_traveller/data/tree_icon_values.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';

List<String> upDateTreeIcons(List<int> emissionValues, int index, Settings settings) {
  if (emissionValues.length <= 1) {
    return [];
  }

  int maxEmission = emissionValues.reduce(max);
  final currentValues = settings.emissionValues;
  
  // Get sorted icons by value in descending order
  final sortedIcons = TreeIconType.values.toList()
    ..sort((a, b) => currentValues[b]!.compareTo(currentValues[a]!));

  int baseTreeIconValue = currentValues[sortedIcons.last]!.toInt();
  List<String> treeIconName = [];

  if (emissionValues.isEmpty) {
    return [];
  }
  
  var dividend = maxEmission - emissionValues[index];

  if (dividend <= 0) {
    return [];
  }

  if (dividend < baseTreeIconValue) {
    treeIconName.add(TreeIconType.defaultOneLeafC02Gram.name);
  }

  // Use sorted icons based on current values
  for (final icon in sortedIcons) {
    final iconValue = currentValues[icon]!.toInt();
    if (iconValue <= 0) continue;

    final count = dividend ~/ iconValue;
    if (count >= 1) {
      final imageRes = _getImageResource(icon);
      treeIconName.addAll(List.filled(count, imageRes));
    }
    dividend %= iconValue;
    
    if (dividend == 0) break;
  }
  
  return treeIconName;
}

String _getImageResource(TreeIconType icon) {
  switch (icon) {
    case TreeIconType.defaultTreeCo2Gram:
      return TreeIconType.defaultTreeCo2Gram.name;
    case TreeIconType.defaultTreeBranchC02Gram:
      return TreeIconType.defaultTreeBranchC02Gram.name;
    case TreeIconType.defaultFourLeavesC02Gram:
      return TreeIconType.defaultFourLeavesC02Gram.name;
    case TreeIconType.defaultOneLeafC02Gram:
      return TreeIconType.defaultOneLeafC02Gram.name;
    }
}