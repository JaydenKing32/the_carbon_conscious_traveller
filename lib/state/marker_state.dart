import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class MarkerState with ChangeNotifier {
  final Set<Marker> _markers = {};
  BitmapDescriptor? _originIcon;

  Set<Marker> get markers => _markers;

  MarkerState() {
    _createOriginMarkerIcon();
  }

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  Future<void> _createOriginMarkerIcon() async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..color = Colors.blue;
    final Paint innerPaint = Paint()..color = Colors.white;

    canvas.drawCircle(const Offset(25, 25), 15, paint);
    canvas.drawCircle(const Offset(25, 25), 7, innerPaint);

    final ui.Image image = await recorder
        .endRecording()
        .toImage(50, 50); 
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    _originIcon = BitmapDescriptor.bytes(uint8List);
    notifyListeners();
  }

  void addOriginMarker(LatLng position) {
    if (_originIcon == null) {
      _markers.removeWhere((marker) => marker.markerId.value == 'origin');
      final Marker originMarker = Marker(
        markerId: const MarkerId('origin'),
        position: position,
        infoWindow: const InfoWindow(title: 'Origin'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
      _markers.add(originMarker);
    } else {
      _markers.removeWhere((marker) => marker.markerId.value == 'origin');
      final Marker originMarker = Marker(
        markerId: const MarkerId('origin'),
        position: position,
        infoWindow: const InfoWindow(title: 'Origin'),
        icon: _originIcon!,
      );
      _markers.add(originMarker);
    }
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
