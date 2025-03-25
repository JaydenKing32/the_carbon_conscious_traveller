import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_directions_api/google_directions_api.dart';

import 'package:the_carbon_conscious_traveller/models/routes_model.dart';
import 'package:the_carbon_conscious_traveller/state/coordinates_state.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/helpers/transit_emissions_calculator.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/list_view_transit.dart';

class Transit extends StatefulWidget {
  const Transit({super.key});

  @override
  State<Transit> createState() => _TransitState();
}

class _TransitState extends State<Transit> {
  final _transitEmissionsCalculator = TransitEmissionsCalculator();

  LatLng? _lastOrigin;
  LatLng? _lastDestination;

  /// We store the current future so the FutureBuilder doesn't re-run constantly.
  Future<List<DirectionsRoute>>? _transitFuture;

  /// This flag ensures we only start one request at a time.
  bool _isFetching = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<CoordinatesState, PolylinesState>(
      builder: (context, coordsState, polylinesState, _) {
        // 1. If no valid coords yet, show a placeholder
        if (coordsState.originCoords == const LatLng(0, 0) || coordsState.destinationCoords == const LatLng(0, 0)) {
          return const Center(child: Text("Please select origin and destination"));
        }

        // 2. Check if origin/destination changed from last time
        bool coordsChanged = (coordsState.originCoords != _lastOrigin) || (coordsState.destinationCoords != _lastDestination);

        // If user changed coords AND we’re not already fetching, start a new request
        if (coordsChanged && !_isFetching) {
          _lastOrigin = coordsState.originCoords;
          _lastDestination = coordsState.destinationCoords;

          // Mark that a request is in progress so we don't double-fetch
          _isFetching = true;

          // Create a new future, but clear _isFetching once it completes
          _transitFuture = _handleTransitMode(coordsState, polylinesState).then((routes) {
            // The future is done, so we can reset _isFetching
            _isFetching = false;
            return routes; // Pass routes on to the FutureBuilder
          });
        }

        // 3. If we never built a future yet, show a small placeholder
        if (_transitFuture == null) {
          return const Text("No Transit data yet.");
        }

        // 4. Build the UI from the future
        return FutureBuilder<List<DirectionsRoute>>(
          future: _transitFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No transit routes found.');
            } else {
              final emissions = _transitEmissionsCalculator.calculateEmissions(context);

              if (emissions.isEmpty) {
                return const Text("No emissions data available");
              }

              return TransitListView(snapshot: snapshot, emissions: emissions, settings: Provider.of<Settings>(context));
            }
          },
        );
      },
    );
  }

  /// Actually fetch the route from Google Directions, but do NOT
  /// call notifyListeners() in the middle of the build.
  Future<List<DirectionsRoute>> _handleTransitMode(
    CoordinatesState coordsState,
    PolylinesState polylinesState,
  ) async {
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

    final fetchedRoutes = await routesModel.getRouteInfo() ?? [];

    // Save data in CoordinatesState outside the build
    coordsState.saveRouteData(fetchedRoutes);

    // Update polylines (listen: false => doesn't trigger immediate rebuild)
    polylinesState.transportMode = 'transit';
    await Provider.of<PolylinesState>(context, listen: false).getPolyline(coordsState.coordinates);

    return fetchedRoutes;
  }
}
