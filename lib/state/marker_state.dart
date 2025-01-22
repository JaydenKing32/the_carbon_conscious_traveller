import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerState extends ChangeNotifier {
  final Set<Marker> _markers = {};

  Set<Marker> get markers => _markers;
  
  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  void addMarker(LatLng position) {
    final newMarker = Marker(
      markerId: MarkerId(position.toString()),
      position: LatLng(position.latitude, position.longitude),
    );
    _markers.add(newMarker);
    notifyListeners();
  }
}
