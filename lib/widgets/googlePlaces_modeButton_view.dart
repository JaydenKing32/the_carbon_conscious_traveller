import 'package:flutter/material.dart';
import 'package:the_carbon_conscious_traveller/widgets/google_places_view.dart';
import 'package:the_carbon_conscious_traveller/widgets/travel_mode_buttons.dart';

class GoogleplacesModebuttonView extends StatefulWidget {
  const GoogleplacesModebuttonView({super.key});

  @override
  State<GoogleplacesModebuttonView> createState() => _GoogleplacesModebuttonViewState();
}

class _GoogleplacesModebuttonViewState extends State<GoogleplacesModebuttonView> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Flexible(
        child: Focus(
          focusNode: _focusNode,
          child:const  GooglePlacesView()),
      ),
         AnimatedOpacity(
          curve: Curves.slowMiddle,
          opacity: _isFocused ? 0 : 1,
          duration: const Duration(milliseconds: 100),
          child: const Flexible(
              child: SizedBox(
            height: 300,
            child: TravelModeButtons(),
          )
               ),
       ),
    ]);
  }
}
