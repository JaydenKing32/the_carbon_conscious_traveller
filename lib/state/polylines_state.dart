import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as poly;
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_carbon_conscious_traveller/models/routes_model.dart';

class PolylinesState extends ChangeNotifier {
  final bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final poly.PolylinePoints _polylinePoints = poly.PolylinePoints();
  final Map<PolylineId, Polyline> _polylines = {};
  final List<List<LatLng>> _routeCoordinates = [];
  List<DirectionsRoute> result = [];
  TravelMode _transportMode = TravelMode.driving;
  String _mode = '';
  int _activeRouteIndex = 0;
  final List<num> _distances = [];
  final List<String> _distanceTexts = [];
  final List<String> _durationTexts = [];
  final List<String> _routeSummary = [];
  int _carActiveRouteIndex = 0;
  int _motorcycleActiveRouteIndex = 0;
  int _transitActiveRouteIndex = 0;
  RoutesModel? routesModel;
  List<DirectionsRoute>? routes = [];
  List<DirectionsRoute> resultForPrivateVehicle = [];

  poly.PolylinePoints get polylinePoints => _polylinePoints;
  Map<PolylineId, Polyline> get polylines => _polylines;
  List<List<LatLng>> get routeCoordinates => _routeCoordinates;
  String get mode => _mode;
  int get activeRouteIndex => _activeRouteIndex;
  List<num> get distances => _distances;
  List<String> get distanceTexts => _distanceTexts;
  List<String> get durationTexts => _durationTexts;
  List<String> get routeSummary => _routeSummary;
  int get carActiveRouteIndex => _carActiveRouteIndex;
  int get motorcycleActiveRouteIndex => _motorcycleActiveRouteIndex;
  int get transitActiveRouteIndex => _transitActiveRouteIndex;

  static const Map<String, TravelMode> _modeMap = {
    'driving': TravelMode.driving,
    'motorcycling': TravelMode.driving,
    'transit': TravelMode.transit,
    'flying': TravelMode.walking, // This should be flying
  };

  set transportMode(String mode) {
    _transportMode = _modeMap[mode]!;
    _mode = mode;
    notifyListeners();
  }

  void resetPolyline() {
    _routeCoordinates.clear();
    notifyListeners();
  }

Future<void> getPolyline(List<LatLng> coordinates) async {
  resetPolyline();

  Future<List<DirectionsRoute>> fetchRouteInfo() async {
    routesModel = RoutesModel(
      origin: GeoCoord(coordinates[0].latitude, coordinates[0].longitude),
      destination: GeoCoord(coordinates[1].latitude, coordinates[1].longitude),
      travelMode: _transportMode,
    );
    routes = await routesModel?.getRouteInfo();
    return routes ?? [];
  }

  // Fetch route info for general use and for driving mode specifically.
  result = await fetchRouteInfo();
  if (_transportMode == TravelMode.driving) {
    resultForPrivateVehicle = await fetchRouteInfo();
  }

  // Clear and update distances for new routes.
  _distances.clear();

  if (result.isNotEmpty) {
    for (int i = 0; i < result.length; i++) {
      List<LatLng> routeCoordinate = [];

      // Skip route if overview polyline is empty.
      if (result[i].overviewPolyline?.points == null ||
          result[i].overviewPolyline!.points!.isEmpty) {
        continue;
      }

      // Decode polyline points for the route.
      List<LatLng> decodedPoints = _polylinePoints
          .decodePolyline(result[i].overviewPolyline!.points!)
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
      routeCoordinate.addAll(decodedPoints);
      routeCoordinates.add(routeCoordinate);

      // Extract distance for the route.
      double routeDistance = 0.0;
      if (result[i].legs != null &&
          result[i].legs!.isNotEmpty &&
          result[i].legs!.first.distance != null) {
        routeDistance = result[i].legs!.first.distance!.value?.toDouble() ?? 0.0;
      }
      _distances.add(routeDistance);
    }
  }

  _updateActiveRoute(_activeRouteIndex);
  notifyListeners();
}


  void _updateActiveRoute(int index) {
    _activeRouteIndex = index;
    polylines.clear();

    for (int i = 0; i < result.length; i++) {
      PolylineId id = PolylineId('poly$i');
      Polyline polyline = Polyline(
        polylineId: id,
        color: i == _activeRouteIndex
            ? const Color.fromARGB(255, 40, 33, 243)
            : const Color.fromARGB(255, 136, 136, 136),
        points: routeCoordinates[i],
        width: i == _activeRouteIndex ? 7 : 5,
        zIndex: i == _activeRouteIndex ? 1 : 0, // Put active route on top
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        consumeTapEvents: true,
        onTap: () => setActiveRoute(i),
      );
      polylines[id] = polyline;
      getDistanceValues();
      getDurationValues();
      getDistanceTexts();
      getDurationTexts();
      getRouteSummary();
    }

    notifyListeners();
  }

  void setActiveRoute(int index) {
    if (index >= 0 && index < _routeCoordinates.length) {
      if (_mode == 'driving') {
        _carActiveRouteIndex = index;
        _updateActiveRoute(_carActiveRouteIndex);
      } else if (_mode == 'motorcycling') {
        _motorcycleActiveRouteIndex = index;
        _updateActiveRoute(_motorcycleActiveRouteIndex);
      } else if (_mode == 'transit') {
        _transitActiveRouteIndex = index;
        _updateActiveRoute(_transitActiveRouteIndex);
      }
    }
    getDistanceValues();
    getDurationValues();
    getDistanceTexts();
    getDurationTexts();
    getRouteSummary();
  }

  int getActiveRoute() {
    if (_mode == 'driving') {
      return _carActiveRouteIndex;
    } else if (_mode == 'motorcycling') {
      return _motorcycleActiveRouteIndex;
    } else if (_mode == 'transit') {
      return _transitActiveRouteIndex;
    } else {
      return _activeRouteIndex;
    }
  }

  void getDistanceValues() {
    if (result.isNotEmpty && _distances.length < result.length) {
      for (var route in result) {
        distances.add(route.legs!.first.distance!.value ?? 0);
      }
    } else {
      "No results";
    }
  }

  void getDistanceTexts() {
    if (result.isNotEmpty && _distanceTexts.length < result.length) {
      for (var route in result) {
        distanceTexts.add(route.legs!.first.distance!.text!);
      }
    } else {
      "No results";
    }
  }

  void getDurationValues() {
    List<num> duration = [];
    if (result.isNotEmpty && _distanceTexts.length < result.length) {
      for (var route in result) {
        duration.add(route.legs!.first.duration!.value!);
      }
    } else {
      "No results";
    }
  }

  void getDurationTexts() {
    if (result.isNotEmpty && _durationTexts.length < result.length) {
      for (var route in result) {
        _durationTexts.add(route.legs!.first.duration!.text!);
      }
    } else {
      "No results";
    }
  }

  void getRouteSummary() {
    if (result.isNotEmpty) {
      for (var route in result) {
        _routeSummary.add(route.summary!);
      }
    } else {
      "No results";
    }
  }

  void clearPolylines() {
    _polylines.clear();
    _routeCoordinates.clear();
    _distances.clear();
    _distanceTexts.clear();
    _durationTexts.clear();
    _routeSummary.clear();
    
    notifyListeners();
  }
}
