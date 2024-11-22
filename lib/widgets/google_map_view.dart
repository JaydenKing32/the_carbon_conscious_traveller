import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:the_carbon_conscious_traveller/helpers/map_service.dart';
import 'package:the_carbon_conscious_traveller/state/marker_state.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:provider/provider.dart';

class GoogleMapView extends StatefulWidget {
  const GoogleMapView({super.key});

  @override
  State<GoogleMapView> createState() => GoogleMapViewState();
}

class GoogleMapViewState extends State<GoogleMapView> {
  @override
  void initState() {
    super.initState();
    final position = MapService().getUserLocation();
    position.then((value) {
      setState(() {
        _currentLocation = maps.LatLng(value!.latitude, value.longitude);
        _initialLocation = maps.CameraPosition(
          target: _currentLocation!,
          zoom: 12.0,
        );
      });
    });
  }

  Set<maps.Marker> markers = {};
  static maps.LatLng? _currentLocation;

  // maps.CameraPosition _originPlace = maps.CameraPosition(
  //   target: _currentPosition ??
  //       const maps.LatLng(-26.853387500000004,
  //           133.27515449999999), // Australia in lieu of user location
  //   zoom: 3.4746,
  // );

  maps.CameraPosition? _initialLocation;

  PolylinePoints polylinePoints = PolylinePoints();
  Map<maps.PolylineId, maps.Polyline> polylines = {};

  @override
  Widget build(BuildContext context) {
    print("GoogleMapViewState $_initialLocation");
    final markerModel = Provider.of<MarkerState>(context);
    final polylineModel = Provider.of<PolylinesState>(context);
    return Scaffold(
      body: _currentLocation == null
          ? Center(
              child: Text(
                'loading map...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : maps.GoogleMap(
              mapType: maps.MapType.normal,
              myLocationEnabled: true,
              initialCameraPosition: _initialLocation!,
              onMapCreated: (maps.GoogleMapController controller) {
                MapService().setController(controller);
              },
              markers: markerModel.markers,
              polylines: Set<maps.Polyline>.of(polylineModel.polylines.values),
            ),
    );
  }
}
