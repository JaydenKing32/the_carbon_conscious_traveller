import 'package:flutter/material.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CoordinatesState with ChangeNotifier {
  final List<LatLng> _coordinates = [];
  LatLng _originCoords = const LatLng(0, 0);
  LatLng _destinationCoords = const LatLng(0, 0);
  final List<DirectionsRoute> _routeData = [];

  List<LatLng> get coordinates => _coordinates;
  LatLng get originCoords => _originCoords;
  LatLng get destinationCoords => _destinationCoords;
  List<DirectionsRoute> get routeData => _routeData;

  void saveCoordinates(LatLng coordinate) {
    coordinates.add(coordinate);
    notifyListeners();
  }

  void saveOriginCoords(LatLng coordinate) {
    _originCoords = coordinate;
    coordinates.add(coordinate);
    notifyListeners();
  }

  void saveDestinationCoords(LatLng coordinate) {
    _destinationCoords = coordinate;
    coordinates.add(coordinate);
    notifyListeners();
  }

  void saveRouteData(List<DirectionsRoute> routeData) {
    for (var route in routeData) {
      if (_routeData.length < routeData.length) {
        _routeData.add(route);
      }
    }
    notifyListeners();
  }

  void clearCoordinates() {
    _coordinates.clear();
    notifyListeners();
  }

  void clearCoordinatesOr() {
    _coordinates.clear();
    _coordinates.add(originCoords);
    notifyListeners();
  }

  void clearCoordinatesDes() {
    _coordinates.clear();
    _coordinates.add(destinationCoords);
    notifyListeners();
  }

  void clearRouteData() {
    _routeData.clear();
    notifyListeners();
  }
}
