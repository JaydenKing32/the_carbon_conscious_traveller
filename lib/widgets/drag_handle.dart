import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/theme_state.dart';

class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child:
          Consumer<ThemeState>(builder: (BuildContext context, theme, child) {
        return Container(
          decoration: BoxDecoration(
            color: theme.isTooLight ? Colors.brown : theme.seedColour,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          height: 4,
          width: 40,
        );
      }),
    );
  }
}
