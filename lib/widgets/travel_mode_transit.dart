import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_directions_api/google_directions_api.dart';

import 'package:the_carbon_conscious_traveller/models/routes_model.dart';
import 'package:the_carbon_conscious_traveller/state/coordinates_state.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/helpers/transit_emissions_calculator.dart';
import 'package:the_carbon_conscious_traveller/widgets/list_view_transit.dart';

class Transit extends StatefulWidget {
  const Transit({Key? key}) : super(key: key);

  @override
  State<Transit> createState() => _TransitState();
}

class _TransitState extends State<Transit> {
  final _transitEmissionsCalculator = TransitEmissionsCalculator();
  // Keep a local cache of the last origin/destination to avoid refetching if unchanged.
  LatLng? _lastOrigin;
  LatLng? _lastDestination;
  Future<List<DirectionsRoute>>? _transitFuture; // store the current future

  @override
  Widget build(BuildContext context) {
    return Consumer2<CoordinatesState, PolylinesState>(
      builder: (context, coordsState, polylinesState, _) {
        // 1. If user hasn’t chosen valid coords yet, show placeholder.
        if (coordsState.originCoords == const LatLng(0, 0) ||
            coordsState.destinationCoords == const LatLng(0, 0)) {
          return const Center(child: Text("Please select origin and destination"));
        }

        // 2. If the origin/destination changed, build a new future.
        bool coordsChanged = (coordsState.originCoords != _lastOrigin) ||
            (coordsState.destinationCoords != _lastDestination);

        if (coordsChanged) {
          _lastOrigin = coordsState.originCoords;
          _lastDestination = coordsState.destinationCoords;

          // Build a new future for transit routes
          _transitFuture = _handleTransitMode(
            coordsState,
            polylinesState,
          );
        }

        // 3. If we have a valid future, show it in a FutureBuilder
        if (_transitFuture == null) {
          // Means we haven't built one yet
          return const Text("No Transit data yet.");
        }

        return FutureBuilder<List<DirectionsRoute>>(
          future: _transitFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No transit routes found.');
            } else {
              // 4. Calculate emissions with the final route data
              final routes = snapshot.data!;
              // Save the route data to coordsState if you want to
              coordsState.saveRouteData(routes);

              final emissions = _transitEmissionsCalculator.calculateEmissions(context);
              if (emissions.isEmpty) {
                return const Text("No emissions data available");
              }

              // 5. Display your list with the new routes
              return TransitListView(
                snapshot: snapshot,
                emissions: emissions,
              );
            }
          },
        );
      },
    );
  }

  /// Actually fetch the route from Google Directions, but do NOT notify
  /// listeners in PolylinesState while it’s still building, to avoid loops.
  Future<List<DirectionsRoute>> _handleTransitMode(
    CoordinatesState coordsState,
    PolylinesState polylinesState,
  ) async {
    // 1) Build a route model from the current coords
    final routesModel = RoutesModel(
      origin: GeoCoord(
        coordsState.originCoords.latitude,
        coordsState.originCoords.longitude,
      ),
      destination: GeoCoord(
        coordsState.destinationCoords.latitude,
        coordsState.destinationCoords.longitude,
      ),
      travelMode: TravelMode.transit,
    );

    // 2) Fetch the transit routes from Google
    final fetchedRoutes = await routesModel.getRouteInfo() ?? [];

    // 3) Update polylines, but using `listen: false` so we don’t cause an immediate rebuild
    polylinesState.transportMode = 'transit';
    await Provider.of<PolylinesState>(context, listen: false)
        .getPolyline(coordsState.coordinates);

    return fetchedRoutes;
  }
}
