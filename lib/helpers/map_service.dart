import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapService {
  static final MapService _instance = MapService._internal();

  factory MapService() {
    return _instance;
  }

  MapService._internal();

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  //go to location when user has entered a location
  Future<void> goToLocation(BuildContext context, LatLng coords) async {
    if (!context.mounted) return;

    final GoogleMapController controller = await _controller.future;

    if (!context.mounted) return;

    await controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            coords.latitude,
            coords.longitude,
          ),
          zoom: 12.0,
        ),
      ),
    );
  }

  //go to the user's current location
  Future<void> goToUserLocation(BuildContext context) async {
    if (!context.mounted) return;

    final GoogleMapController controller = await _controller.future;

    if (!context.mounted) return;

    if (_currentPosition != null) {
      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 12.0,
          ),
        ),
      );
    }
  }

  Position? _currentPosition;

  getPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
// Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }
// Request permission to get the user's location
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return null;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }
    }
  }

  Future<Position?> getUserLocation() async {
    await getPermission();
    _currentPosition = await Geolocator.getCurrentPosition();
    return _currentPosition;
  }

  void setController(GoogleMapController controller) {
    _controller.complete(controller);
  }

  Future<Placemark?> getAddressFromLatLng() async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude);
    return placemarks.isNotEmpty ? placemarks[0] : null;
  }

  LatLng? getUserLatLng() {
    return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
  }
}
