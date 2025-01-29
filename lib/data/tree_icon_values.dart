enum TreeIconType {
  defaultOneLeafC02Gram,
  defaultFourLeavesC02Gram,
  defaultTreeBranchC02Gram,
  defaultTreeCo2Gram,
}

extension TreeIconTypeExtension on TreeIconType {
  double get value {
    switch (this) {
      case TreeIconType.defaultOneLeafC02Gram:
        return 100;
      case TreeIconType.defaultFourLeavesC02Gram:
        return 1000;
      case TreeIconType.defaultTreeBranchC02Gram:
        return 5000;
      case TreeIconType.defaultTreeCo2Gram:
        return 29000;
      }
  }
}

extension TreeIconName on TreeIconType {
  String get name {
    switch (this) {
      case TreeIconType.defaultOneLeafC02Gram:
        return "leaf2.png";
      case TreeIconType.defaultFourLeavesC02Gram:
        return "four_leaves1.png";
      case TreeIconType.defaultTreeBranchC02Gram:
        return "tree_branch3.png";
      case TreeIconType.defaultTreeCo2Gram:
        return "tree2.png";
      }
  }

  String get emoji {
    switch (this) {
      case TreeIconType.defaultOneLeafC02Gram:
        return "🍃";
      case TreeIconType.defaultFourLeavesC02Gram:
        return "🍀";
      case TreeIconType.defaultTreeBranchC02Gram:
        return "🌿";
      case TreeIconType.defaultTreeCo2Gram:
        return "🌳";
      }
  }

  String get description {
    switch (this) {
      case TreeIconType.defaultOneLeafC02Gram:
        return "Single Leaf";
      case TreeIconType.defaultFourLeavesC02Gram:
        return "Leaf bundle";
      case TreeIconType.defaultTreeBranchC02Gram:
        return "Tree Branch";
      case TreeIconType.defaultTreeCo2Gram:
        return "Full Tree";
      }
  }
}