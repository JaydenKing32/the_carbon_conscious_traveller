import 'package:flutter/material.dart';
import 'package:the_carbon_conscious_traveller/helpers/map_service.dart';

class LocationButton extends StatelessWidget {
  const LocationButton({super.key, required this.callback});

  final VoidCallback callback;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          MapService().goToUserLocation(context);
          callback();
        },
        icon: const Icon(Icons.my_location_outlined));
  }
}
