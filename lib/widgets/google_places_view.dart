// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as places;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_directions_api/google_directions_api.dart' as dir;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_carbon_conscious_traveller/constants.dart';
import 'package:the_carbon_conscious_traveller/data/calculation_values.dart';
import 'package:the_carbon_conscious_traveller/helpers/map_service.dart';
import 'package:the_carbon_conscious_traveller/helpers/private_car_emissions_calculator.dart';
import 'package:the_carbon_conscious_traveller/helpers/private_vehicle_emissions_calculator.dart';
import 'package:the_carbon_conscious_traveller/state/marker_state.dart';
import 'package:the_carbon_conscious_traveller/state/coordinates_state.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/models/routes_model.dart';
import 'package:the_carbon_conscious_traveller/state/private_car_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_motorcycle_state.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/location_button.dart';
import 'package:the_carbon_conscious_traveller/widgets/travel_mode_buttons.dart';

class GooglePlacesView extends StatefulWidget {
  const GooglePlacesView({super.key});

  @override
  State<GooglePlacesView> createState() => _GooglePlacesViewState();
}

class _GooglePlacesViewState extends State<GooglePlacesView> {
  late final places.FlutterGooglePlacesSdk _places;
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  final FocusNode _originFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  bool _isSettingControllerText = false;

  PolylinePoints polylinePoints = PolylinePoints();

  places.Place? origin;
  places.Place? destination;
  places.LatLng? originLatLng;
  places.LatLng? destinationLatLng;
  String? _predictLastText;
  String fieldType = ""; // "start" or "destination"
  final List<String> _countries = [];
  List<places.AutocompletePrediction>? _predictions;
  bool _predicting = false;
  bool _fetchingPlace = false;
  dynamic _fetchingPlaceErr;
  dynamic _predictErr;

  RoutesModel? routes;

  final List<places.PlaceField> _placeFields = [
    places.PlaceField.Address,
    places.PlaceField.Location,
  ];

  final travelMode = dir.TravelMode.driving;

  @override
  void initState() {
    super.initState();
    const googleApiKey = Constants.googleApiKey;
    const initialLocale = Constants.initialLocale;

    // Initialise Google Places API
    _places = places.FlutterGooglePlacesSdk(
      googleApiKey,
      locale: initialLocale,
    );
    _places.isInitialized().then((value) {
      debugPrint('Places Initialised: $value');
    });
  }

  @override
  Widget build(BuildContext context) {
    final predictionsWidgets = _buildPredictionWidgets();

    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(children: predictionsWidgets),
      ),
    );
  }

  List<Widget> _buildPredictionWidgets() {
    return [
      Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 20),
          child: Column(
            children: [
              // --- ORIGIN ---
              TextFormField(
                controller: originController,
                focusNode: _originFocusNode,
                onTapOutside: (PointerDownEvent event) {
                  _originFocusNode.unfocus();
                  setState(() {
                    FocusScope.of(context).unfocus();
                  });
                },
                onChanged: (value) => _onPredictTextChanged(value, "start"),
                decoration: InputDecoration(
                  label: const Text("Enter a start location"),
                  icon: const Icon(
                    Icons.location_searching_outlined,
                    color: Colors.grey,
                  ),
                  suffixIcon: LocationButton(callback: getUserLocationDetails),
                ),
              ),
              // --- DESTINATION ---
              TextFormField(
                controller: destinationController,
                focusNode: _destinationFocusNode,
                onTapOutside: (PointerDownEvent event) {
                  setState(() {
                    _destinationFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                  });
                },
                onChanged: (value) => _onPredictTextChanged(value, "destination"),
                decoration: const InputDecoration(
                  label: Text("Enter a destination"),
                  icon: Icon(Icons.location_searching_outlined, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
      Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: (_predictions ?? []).map(_buildPredictionItem).toList(growable: false),
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 10.0),
        child: Image(
          image: places.FlutterGooglePlacesSdk.ASSET_POWERED_BY_GOOGLE_ON_WHITE,
        ),
      ),
      // Travel mode buttons
      const TravelModeButtons(),
      if (_fetchingPlaceErr != null || _predictErr != null) ...[
        _buildErrorWidget(_fetchingPlaceErr),
        _buildErrorWidget(_predictErr),
      ],
    ];
  }

  Widget _buildPredictionItem(places.AutocompletePrediction item) {
    return InkWell(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          _predictions = [];
        }
      },
      onTap: () => _onItemTapped(item),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 40,
              right: 10,
              top: 10,
              bottom: 10,
            ),
            child: Text(
              item.fullText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Divider(thickness: 1),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(dynamic err) {
    final theme = Theme.of(context);
    final errorText = err == null ? '' : err.toString();
    return Text(
      errorText,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }

  /// 1) On text change, store "start" or "destination" so we know which field is being typed.
  void _onPredictTextChanged(String value, String field) {
    if (_isSettingControllerText) return;
    _predictLastText = value;
    fieldType = field;
    _predict();
  }

  /// 2) Actually do the Places autocomplete
  void _predict() async {
    if (_predicting) return;

    final hasContent = _predictLastText?.isNotEmpty ?? false;
    setState(() {
      _predicting = hasContent;
      _predictErr = null;
    });

    if (!hasContent) return;

    try {
      final result = await _places.findAutocompletePredictions(
        _predictLastText!,
        countries: _countries,
        newSessionToken: false,
      );
      setState(() {
        _predictions = result.predictions;
        _predicting = false;
      });
    } catch (err) {
      setState(() {
        _predictErr = err;
        _predicting = false;
      });
    }
  }

  /// 3) On picking one of the predictions, fetch its details + do marker logic
  void _onItemTapped(places.AutocompletePrediction item) async {
    if (_fetchingPlace) return; // Already fetching

    try {
      final result = await _places.fetchPlace(
        item.placeId,
        fields: _placeFields,
      );

      final coordsState = Provider.of<CoordinatesState>(context, listen: false);
      final polylineState = Provider.of<PolylinesState>(context, listen: false);

      polylineState.clearPolylines();
      coordsState.clearCoordinates();
      coordsState.clearRouteData();

      _isSettingControllerText = true;

      if (fieldType == "start") {
        // Mark new origin
        coordsState.clearCoordinatesDes(); // Clear old destination
        originController.text = item.fullText;
        setState(() {
          origin = result.place;
          _fetchingPlace = false;
          originLatLng = origin?.latLng;
          _predictions = [];
        });

        if (originLatLng != null) {
          LatLng latlng = LatLng(originLatLng!.lat, originLatLng!.lng);
          _addOriginMarker(latlng);
          if (mounted) {
            MapService().goToLocation(context, latlng);
          }
        }
      } else if (fieldType == "destination") {
        // Mark new destination
        coordsState.clearCoordinatesOr(); // Clear old origin
        destinationController.text = item.fullText;
        setState(() {
          destination = result.place;
          _fetchingPlace = false;
          destinationLatLng = destination?.latLng;
          _predictions = [];
        });

        if (destinationLatLng != null) {
          LatLng latlng = LatLng(destinationLatLng!.lat, destinationLatLng!.lng);
          _addDestinationMarker(latlng);
          if (mounted) {
            MapService().goToLocation(context, latlng);
          }
        }
      }

      if (coordsState.originCoords != const LatLng(0, 0) && coordsState.destinationCoords != const LatLng(0, 0)) {
        if (polylineState.mode.isEmpty) {
          polylineState.transportMode = "driving"; // Default
        }
      }

      _isSettingControllerText = false;
      _originFocusNode.unfocus();
      _destinationFocusNode.unfocus();
      FocusScope.of(context).unfocus();
    } catch (err) {
      setState(() {
        _fetchingPlaceErr = err;
        _fetchingPlace = false;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Markers + Emissions
  // -------------------------------------------------------------------------

  void _addOriginMarker(LatLng originLatLng) {
    final markerModel = Provider.of<MarkerState>(context, listen: false);
    final coordinatesModel = Provider.of<CoordinatesState>(context, listen: false);
    final polylineState = Provider.of<PolylinesState>(context, listen: false);
    final carState = Provider.of<PrivateCarState>(context, listen: false);
    final motorcycleState = Provider.of<PrivateMotorcycleState>(context, listen: false);

    // Place the origin marker
    markerModel.addOriginMarker(originLatLng);
    coordinatesModel.saveOriginCoords(originLatLng);

    // If we already have a destination, fetch polylines & recalc emissions
    if (coordinatesModel.destinationCoords != const LatLng(0, 0)) {
      // Reset emissions
      carState.resetEmissions();
      motorcycleState.resetEmissions();

      polylineState.getPolyline([coordinatesModel.originCoords, coordinatesModel.destinationCoords]).then((_) {
        if (polylineState.distances.isEmpty) {
          return;
        }

        try {
          // Calculate Car Emissions
          final settings = Provider.of<Settings>(context, listen: false);
          final emissionsCalculator = PrivateCarEmissionsCalculator(
            polylinesState: polylineState,
            settings: settings,
            routeCarSize: carState.selectedSize ?? CarSize.label,
            routeCarFuel: carState.selectedFuelType ?? CarFuelType.label,
          );
          final List<int> calculatedCarEmissions = [];
          for (int i = 0; i < polylineState.distances.length; i++) {
            double emission = emissionsCalculator.calculateEmissions(
              i,
              carState.selectedSize ?? CarSize.label,
              carState.selectedFuelType ?? CarFuelType.label,
            );
            calculatedCarEmissions.add(emission.toInt());
          }
          carState.saveEmissions(calculatedCarEmissions);
          if (calculatedCarEmissions.isNotEmpty) {
            carState.updateMinEmission(calculatedCarEmissions.reduce(min));
            carState.updateMaxEmission(calculatedCarEmissions.reduce(max));
          }

          // Calculate Motorcycle Emissions
          final motoEmissionsCalc = PrivateVehicleEmissionsCalculator(
            polylinesState: polylineState,
            settings: settings,
            routeBikeSize: motorcycleState.selectedValue ?? MotorcycleSize.label,
          );
          final List<int> calculatedMotoEmissions = [];
          for (int i = 0; i < polylineState.distances.length; i++) {
            double emission = motoEmissionsCalc.calculateEmission(i);
            calculatedMotoEmissions.add(emission.toInt());
          }
          motorcycleState.saveEmissions(calculatedMotoEmissions);
          if (calculatedMotoEmissions.isNotEmpty) {
            motorcycleState.updateMinEmission(calculatedMotoEmissions.reduce(min));
            motorcycleState.updateMaxEmission(calculatedMotoEmissions.reduce(max));
          }
        } catch (e) {
          debugPrint("Error calculating emissions: $e");
        }
      }).catchError((error) {
        debugPrint("Error in getPolyline for origin: $error");
      });
    }
  }

  void _addDestinationMarker(LatLng destinationLatLng) {
    final markerModel = Provider.of<MarkerState>(context, listen: false);
    final coordinatesModel = Provider.of<CoordinatesState>(context, listen: false);
    final polylineState = Provider.of<PolylinesState>(context, listen: false);
    final carState = Provider.of<PrivateCarState>(context, listen: false);
    final motorcycleState = Provider.of<PrivateMotorcycleState>(context, listen: false);

    // Place the destination marker
    markerModel.addDestinationMarker(destinationLatLng);
    coordinatesModel.saveDestinationCoords(destinationLatLng);

    // If we already have an origin, fetch polylines & recalc emissions
    if (coordinatesModel.originCoords != const LatLng(0, 0)) {
      // Reset emissions
      carState.resetEmissions();
      motorcycleState.resetEmissions();

      polylineState.getPolyline([coordinatesModel.originCoords, coordinatesModel.destinationCoords]).then((_) {
        if (polylineState.distances.isEmpty) {
          return;
        }

        try {
          // Calculate Car Emissions
          final settings = Provider.of<Settings>(context, listen: false);

          final emissionsCalculator = PrivateCarEmissionsCalculator(
            polylinesState: polylineState,
            settings: settings,
            routeCarSize: carState.selectedSize ?? CarSize.label,
            routeCarFuel: carState.selectedFuelType ?? CarFuelType.label,
          );

          final List<int> calculatedCarEmissions = [];
          for (int i = 0; i < polylineState.distances.length; i++) {
            double emission = emissionsCalculator.calculateEmissions(
              i,
              carState.selectedSize ?? CarSize.label,
              carState.selectedFuelType ?? CarFuelType.label,
            );
            calculatedCarEmissions.add(emission.toInt());
          }
          carState.saveEmissions(calculatedCarEmissions);
          if (calculatedCarEmissions.isNotEmpty) {
            carState.updateMinEmission(calculatedCarEmissions.reduce(min));
            carState.updateMaxEmission(calculatedCarEmissions.reduce(max));
          }

          // Calculate Motorcycle Emissions
          final motoEmissionsCalc = PrivateVehicleEmissionsCalculator(
            polylinesState: polylineState,
            settings: settings,
            routeBikeSize: motorcycleState.selectedValue ?? MotorcycleSize.label,
          );
          final List<int> calculatedMotoEmissions = [];
          for (int i = 0; i < polylineState.distances.length; i++) {
            double emission = motoEmissionsCalc.calculateEmission(i);
            calculatedMotoEmissions.add(emission.toInt());
          }
          motorcycleState.saveEmissions(calculatedMotoEmissions);
          if (calculatedMotoEmissions.isNotEmpty) {
            motorcycleState.updateMinEmission(calculatedMotoEmissions.reduce(min));
            motorcycleState.updateMaxEmission(calculatedMotoEmissions.reduce(max));
          }
        } catch (e) {
          debugPrint("Error calculating emissions: $e");
        }
      }).catchError((error) {
        debugPrint("Error in getPolyline for destination: $error");
      });
    }
  }

  // -------------------------------------------------------------------------
  // Geolocate user
  // -------------------------------------------------------------------------
  void getUserLocationDetails() {
    final place = MapService().getAddressFromLatLng();
    place.then((placemark) {
      if (placemark != null) {
        final currentAddress = "${placemark.street!} ${placemark.locality!} ${placemark.postalCode!} ${placemark.country!}";
        setState(() {
          originController.text = currentAddress;
        });
      } else {
        _buildErrorWidget("Address not found. Try entering an address manually");
      }
    });
    setUserMarker();
  }

  void setUserMarker() {
    final latLng = MapService().getUserLatLng();
    if (latLng != null) {
      _addOriginMarker(latLng);
    }
  }
}
