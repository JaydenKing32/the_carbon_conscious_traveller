import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:the_carbon_conscious_traveller/constants.dart';

class RoutesModel {
  final GeoCoord origin;
  final GeoCoord destination;
  final TravelMode travelMode;
  final String googleApiKey = Constants.googleApiKey;
  //List<DirectionsRoute>? routes;

  RoutesModel({
    required this.origin,
    required this.destination,
    required this.travelMode,
  });

  DirectionsRequest getRequest() {
    DirectionsService.init(googleApiKey);
    return DirectionsRequest(
      origin: origin,
      destination: destination,
      travelMode: travelMode,
      alternatives: true,
    );
  }

  Future<List<DirectionsRoute>> getRouteInfo() async {
    final directionsService = DirectionsService();
    final request = getRequest();
    final completer = Completer<dynamic>();

    directionsService.route(request,
        (DirectionsResult response, DirectionsStatus? status) {
      debugPrint("Full response: ${response.routes?.length}");
      if (status == DirectionsStatus.ok) {
        debugPrint("Test Request successful");
        final routes = response.routes;
        if (!completer.isCompleted) {
          completer.complete(routes);
        }
      } else {
        debugPrint("Test Request unsuccessful");
        if (!completer.isCompleted) {
          completer.completeError("Request unsuccessful");
        }
      }
    });

    try {
      final routes = await completer.future;
      debugPrint("Request completed");
      debugPrint("ROUTES result length ${routes?.length}");
      return routes;
    } catch (e) {
      debugPrint("Error: $e");
      return [];
    }
  }
}
