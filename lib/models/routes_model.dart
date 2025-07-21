import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:the_carbon_conscious_traveller/constants.dart';

class RoutesModel {
  final GeoCoord origin;
  final GeoCoord destination;
  final TravelMode travelMode;
  final String googleApiKey = Constants.googleApiKey;

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

    directionsService.route(request, (DirectionsResult response, DirectionsStatus? status) {
      if (kDebugMode) {
        debugPrint("Full response: ${response.routes?.length}");
      }
      if (status == DirectionsStatus.ok) {
        final routes = response.routes;
        if (!completer.isCompleted) {
          completer.complete(routes);
        }
      } else {
        if (!completer.isCompleted) {
          completer.completeError("Request unsuccessful");
        }
      }
    });

    try {
      final routes = await completer.future;
      if (kDebugMode) {
        debugPrint("ROUTES result length ${routes?.length}");
      }
      return routes;
    } catch (e) {
      debugPrint("Error: $e");
      return [];
    }
  }
}
