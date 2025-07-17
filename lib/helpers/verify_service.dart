import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_carbon_conscious_traveller/db/trip_database.dart';
import 'package:the_carbon_conscious_traveller/helpers/dynamo_helper.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';

@pragma("vm:entry-point")
class VerifyService {
  static void startBackgroundService() {
    debugPrint("Starting location verification");
    final service = FlutterBackgroundService();
    service.startService();
  }

  static void stopBackgroundService() {
    final service = FlutterBackgroundService();
    service.invoke("stop");
  }

  static Future<bool> isRunning() {
    final service = FlutterBackgroundService();
    return service.isRunning();
  }

  static Future<void> initializeService() async {
    debugPrint("Initialising location verification");
    // Add permission checks
    final service = FlutterBackgroundService();

    await service.configure(
      iosConfiguration: IosConfiguration(autoStart: false, onForeground: onStart),
      androidConfiguration: AndroidConfiguration(autoStart: true, onStart: onStart, isForegroundMode: true, autoStartOnBoot: false),
    );
  }

  static void update(List<LatLng> coords, int tripId) {
    final service = FlutterBackgroundService();
    service.invoke("cancel"); // Stop any existing processes
    service.invoke("update", {"coords": coords, "trip": tripId});
  }

  @pragma("vm:entry-point")
  static void onStart(ServiceInstance service) async {
    const double distThreshold = 50;
    const int checkInterval = kReleaseMode ? 60 : 10;
    final bool enableEventMode = (await SharedPreferences.getInstance()).getBool("enableEventMode") ?? false;

    service.on("stop").listen((event) {
      service.stopSelf();
    });

    service.on("update").listen((event) async {
      final coords = event?["coords"];
      final tripId = event?["trip"];

      final Trip? trip = await TripDatabase.instance.getTripById(tripId);
      Fluttertoast.showToast(msg: "Starting trip");
      debugPrint("Starting location verification with $trip");

      Timer.periodic(const Duration(seconds: checkInterval), (timer) async {
        service.on("cancel").listen((event) {
          timer.cancel();
        });

        final curPos = await Geolocator.getCurrentPosition();
        double dist = Geolocator.distanceBetween(curPos.latitude, curPos.longitude, coords.last[0], coords.last[1]);

        if (dist <= distThreshold) {
          await TripDatabase.instance.updateTripCompletion(tripId, true);
          Fluttertoast.showToast(msg: "Completed trip");
          debugPrint("Completed trip");
          if (enableEventMode) {
            await DynamoHelper.insertTrip(trip);
          }
          service.stopSelf();
          return;
        }

        for (final coord in coords) {
          debugPrint("Checking coordinates $coord");
          double dist = Geolocator.distanceBetween(curPos.latitude, curPos.longitude, coord[0], coord[1]);
          if (dist <= distThreshold) {
            // User is on-route
            return;
          }
        }

        await TripDatabase.instance.deleteTrip(tripId);
        Fluttertoast.showToast(msg: "Cancelling trip");
        debugPrint("Cancelling trip");
        service.stopSelf();
      });
    });
  }
}
