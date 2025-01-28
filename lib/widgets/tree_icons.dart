import 'package:flutter/material.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';

class TreeIcons extends StatelessWidget {
  const TreeIcons({super.key, required this.treeIconName, required Settings settings});

  final List treeIconName;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (String treeIcon in treeIconName)
          Image.asset(
            'assets/icons/$treeIcon',
            width: 20,
            height: 20,
          ),
      ],
    );
  }
}
