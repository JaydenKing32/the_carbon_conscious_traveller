// MarkerState.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerState with ChangeNotifier {
  final Set<Marker> _markers = {};

  Set<Marker> get markers => _markers;
  
  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  void addOriginMarker(LatLng position) {
    _markers.removeWhere((marker) => marker.markerId.value == 'origin');
    final Marker originMarker = Marker(
      markerId: const MarkerId('origin'),
      position: position,
      infoWindow: const InfoWindow(title: 'Origin'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    _markers.add(originMarker);
    notifyListeners();
  }

  void addDestinationMarker(LatLng position) {
    _markers.removeWhere((marker) => marker.markerId.value == 'destination');
    final Marker destinationMarker = Marker(
      markerId: const MarkerId('destination'),
      position: position,
      infoWindow: const InfoWindow(title: 'Destination'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
    _markers.add(destinationMarker);
    notifyListeners();
  }
}
