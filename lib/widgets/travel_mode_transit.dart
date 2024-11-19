import 'package:flutter/material.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/coordinates_state.dart';
import 'package:the_carbon_conscious_traveller/models/routes_model.dart';
import 'package:the_carbon_conscious_traveller/helpers/transit_emissions_calculator.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/list_view_transit.dart';

class Transit extends StatefulWidget {
  const Transit({super.key});

  @override
  State<Transit> createState() => _TransitState();
}

class _TransitState extends State<Transit> {
  final travelMode = TravelMode.transit;
  RoutesModel? routesModel;
  List<DirectionsRoute>? routes = [];
  TransitEmissionsCalculator? _transitEmissionsCalculator;
  late CoordinatesState coordsState;
  late PolylinesState polylinesState;

  @override
  void initState() {
    _transitEmissionsCalculator = TransitEmissionsCalculator();
    coordsState = Provider.of<CoordinatesState>(context, listen: false);
    polylinesState = Provider.of<PolylinesState>(context, listen: false);
    super.initState();
  }

  Future<List<DirectionsRoute>> fetchRouteInfo() async {
    routesModel = RoutesModel(
      origin: GeoCoord(coordsState.originCoords.latitude,
          coordsState.originCoords.longitude),
      destination: GeoCoord(coordsState.destinationCoords.latitude,
          coordsState.destinationCoords.longitude),
      travelMode: TravelMode.transit,
    );
    routes = await routesModel?.getRouteInfo();
    if (routes == null) {
      return [];
    } else {
      coordsState.saveRouteData(routes!);
      return routes!;
    }
  }

  Future<List<DirectionsRoute>> handleTransitMode() async {
    await fetchRouteInfo();
    polylinesState.getPolyline(coordsState.coordinates);
    return routes ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DirectionsRoute>>(
      future: handleTransitMode(),
      builder: (context, snapshot) {
        final emissions =
            _transitEmissionsCalculator?.calculateEmissions(context);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            heightFactor: 1.5,
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return snapshot.data == null
              ? const Text('No data available')
              : Column(
                  children: [
                    if (emissions != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TransitListView(
                            snapshot: snapshot, emissions: emissions),
                      )
                    else
                      const Text('No emissions data available')
                  ],
                );
        } else {
          return const Text('No data available');
        }
      },
    );
  }
}
