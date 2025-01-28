// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places;
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

  places.Place? origin; //starting location
  places.Place? destination; //end location
  places.LatLng? originLatLng; //starting coordinates
  places.LatLng? destinationLatLng; //end coordinates
  String? _predictLastText; // Last text used for prediction
  String fieldType = ""; // Origin or destination
  final List<String> _countries = []; // Preset countries
  List<places.AutocompletePrediction>? _predictions; // Predictions
  bool _predicting = false; // Predicting state
  bool _fetchingPlace = false; // Fetching place state
  dynamic _fetchingPlaceErr; // Fetching place error
  dynamic _predictErr; // Prediction error

  RoutesModel? routes;

  // Place fields to fetch when a prediction is clicked
  final List<places.PlaceField> _placeFields = [
    places.PlaceField.Address,
    places.PlaceField.Location,
  ];

  @override
  void initState() {
    super.initState();

    const googleApiKey = Constants.googleApiKey;
    const initialLocale = Constants.initialLocale;

    // Initialise Google Places API
    _places =
        places.FlutterGooglePlacesSdk(googleApiKey, locale: initialLocale);
    _places.isInitialized().then((value) {
      debugPrint('Places Initialised: $value');
    });
  }

  final travelMode = dir.TravelMode.driving;

  @override
  Widget build(BuildContext context) {
    final predictionsWidgets = _buildPredictionWidgets();

    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            ...predictionsWidgets,
          ],
        ),
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
              TextFormField(
                controller: originController,
                focusNode: _originFocusNode, // Assign focus node
                onTapOutside: (PointerDownEvent event) {
                   _originFocusNode.unfocus();
                  setState(() {
                    //hide the keyboard when the user taps outside the textfield
                    FocusScope.of(context).unfocus();
                  });
                },
                onChanged: (value) => _onPredictTextChanged(value, "start"),
                decoration: InputDecoration(
                    label: const Text("Enter a start location"),
                    icon: const Icon(Icons.location_searching_outlined,
                        color: Colors.grey),
                    suffixIcon:
                        LocationButton(callback: getUserLocationDetails)),
              ),
              TextFormField(
                controller: destinationController,
                focusNode: _destinationFocusNode,
                onTapOutside: (PointerDownEvent event) {
                  setState(() {
                    _destinationFocusNode.unfocus(); 
                    //hide the keyboard when the user taps outside the textfield
                    FocusScope.of(context).unfocus();
                  });
                },
              
                onChanged: (value) =>
                    _onPredictTextChanged(value, "destination"),
                decoration: const InputDecoration(
                  label: Text("Enter a destination"),
                  icon: Icon(Icons.location_searching_outlined,
                      color: Colors.grey),
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
          children: (_predictions ?? [])
              .map(_buildPredictionItem)
              .toList(growable: false),
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 10.0),
        child: Image(
          image: places.FlutterGooglePlacesSdk.ASSET_POWERED_BY_GOOGLE_ON_WHITE,
        ),
      ),
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
                  left: 40, right: 10, top: 10.0, bottom: 10),
              child: Text(item.fullText,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const Divider(thickness: 1),
          ]),
    );
  }

  Widget _buildErrorWidget(dynamic err) {
    final theme = Theme.of(context);
    final errorText = err == null ? '' : err.toString();
    return Text(errorText,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.error));
  }

  //Save the last text input and the field type
  void _onPredictTextChanged(String value, String field) async {
    if (_isSettingControllerText) return; 
    _predictLastText = value;
    fieldType = field;

    _predict();
  }

  //Predict the last text input
  void _predict() async {
    if (_predicting) {
      return;
    }

    final hasContent = _predictLastText?.isNotEmpty ?? false;

    setState(() {
      _predicting = hasContent;
      _predictErr = null;
    });

    if (!hasContent) {
      return;
    }

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

  //When a predicted item is clicked, fetch the place details
  void _onItemTapped(places.AutocompletePrediction item) async {
  if (_fetchingPlace) {
    return; // Fetching in progress
  }

  try {
    final result = await _places.fetchPlace(item.placeId, fields: _placeFields);

    final markerState = Provider.of<MarkerState>(context, listen: false);
    final coordsState = Provider.of<CoordinatesState>(context, listen: false);
    final polylineState = Provider.of<PolylinesState>(context, listen: false);

    // Clear previous markers and polylines before adding new ones
    //markerState.clearMarkers();
    polylineState.clearPolylines();
    coordsState.clearCoordinates(); // if needed
    coordsState.clearRouteData();   // if needed
    // If coordinates are set, fetch new polyline
    _isSettingControllerText = true;

    if (fieldType == "start") {
      coordsState.clearCoordinatesDes();
      originController.text = item.fullText;
      setState(() {
        origin = result.place;
        _fetchingPlace = false;
        originLatLng = origin?.latLng;
        _predictions = [];
      });

      if (originLatLng != null) {
        LatLng originPosition = LatLng(originLatLng!.lat, originLatLng!.lng);
        _addOriginMarker(originPosition);
        if (mounted) {
          MapService().goToLocation(context, originPosition);
        }
      }
    } else if (fieldType == "destination") {
      coordsState.clearCoordinatesOr();
      destinationController.text = item.fullText;
      setState(() {
        destination = result.place;
        _fetchingPlace = false;
        destinationLatLng = destination?.latLng;
        _predictions = [];
      });
      
      if (destinationLatLng != null) {
        LatLng destPosition = LatLng(destinationLatLng!.lat, destinationLatLng!.lng);
        _addDestinationMarker(destPosition);
        if (mounted) {
          MapService().goToLocation(context, destPosition);
        }
      }
    }
     if (coordsState.coordinates.isNotEmpty) {
                      polylineState.setActiveRoute(polylineState.getActiveRoute());
                      polylineState.getPolyline(coordsState.coordinates);
                    }
    // **Set default transport mode after both origin and destination are set**
    if (coordsState.originCoords != const LatLng(0, 0) &&
        coordsState.destinationCoords != const LatLng(0, 0)) {
      if (polylineState.mode.isEmpty) {
        polylineState.transportMode = "driving"; // Default mode
      }

      _isSettingControllerText = false;
_originFocusNode.unfocus();
    _destinationFocusNode.unfocus();

      // Alternatively, set based on user selection
      FocusScope.of(context).unfocus();
    }
  } catch (err) {
    setState(() {
      _fetchingPlaceErr = err;
      _fetchingPlace = false;
    });
  }
}



// Update GooglePlacesView.dart

void _addOriginMarker(LatLng originLatLng) {
  final markerModel = Provider.of<MarkerState>(context, listen: false);
  markerModel.addOriginMarker(originLatLng);; // Use unique ID for origin

  final coordinatesModel = Provider.of<CoordinatesState>(context, listen: false);
  coordinatesModel.saveOriginCoords(originLatLng);

  if (coordinatesModel.destinationCoords != const LatLng(0, 0)) {
    final polylineState = Provider.of<PolylinesState>(context, listen: false);

    // Reset emissions for both Car and Motorcycle
    final carState = Provider.of<PrivateCarState>(context, listen: false);
    final motorcycleState = Provider.of<PrivateMotorcycleState>(context, listen: false);

    carState.resetEmissions();
    motorcycleState.resetEmissions();

    polylineState.getPolyline([
      coordinatesModel.originCoords,
      coordinatesModel.destinationCoords
    ]).then((_) {
      if (polylineState.distances.isEmpty) {
        return;
      }

      try {
        // **Calculate Emissions for Car**
        final emissionsCalculator = PrivateCarEmissionsCalculator(
          polylinesState: polylineState,
          vehicleSize: carState.selectedSize ?? CarSize.label,
          vehicleFuelType: carState.selectedFuelType ?? CarFuelType.label,
        );

        List<int> calculatedCarEmissions = [];
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

        // **Calculate Emissions for Motorcycle**
        final motorcycleEmissionsCalculator = PrivateVehicleEmissionsCalculator(
          polylinesState: polylineState,
          vehicleSize: motorcycleState.selectedValue ?? MotorcycleSize.label,
        );

        List<int> calculatedMotorcycleEmissions = [];
        for (int i = 0; i < polylineState.distances.length; i++) {
          double emission = motorcycleEmissionsCalculator.calculateEmission(i);
          calculatedMotorcycleEmissions.add(emission.toInt());
        }

        motorcycleState.saveEmissions(calculatedMotorcycleEmissions);
        if (calculatedMotorcycleEmissions.isNotEmpty) {
          motorcycleState.updateMinEmission(calculatedMotorcycleEmissions.reduce(min));
          motorcycleState.updateMaxEmission(calculatedMotorcycleEmissions.reduce(max));
        }
      } catch (e) {
        // Handle errors if necessary
      }
    }).catchError((error) {
      // Handle errors if necessary
    });
  }
}

void _addDestinationMarker(LatLng destinationLatLng) {
  final markerModel = Provider.of<MarkerState>(context, listen: false);
  markerModel.addDestinationMarker(destinationLatLng); 

  final coordsState = Provider.of<CoordinatesState>(context, listen: false);
  coordsState.saveDestinationCoords(destinationLatLng);

  if (coordsState.originCoords != const LatLng(0, 0)) {
    final polylineState = Provider.of<PolylinesState>(context, listen: false);


    final carState = Provider.of<PrivateCarState>(context, listen: false);
    final motorcycleState = Provider.of<PrivateMotorcycleState>(context, listen: false);

    carState.resetEmissions();
    motorcycleState.resetEmissions();

    polylineState.getPolyline([
      coordsState.originCoords,
      coordsState.destinationCoords
    ]).then((_) {
      if (polylineState.distances.isEmpty) {
        return;
      }

      try {
        
        // **Calculate Emissions for Car**
        final emissionsCalculator = PrivateCarEmissionsCalculator(
          polylinesState: polylineState,
          vehicleSize: carState.selectedSize ?? CarSize.label,
          vehicleFuelType: carState.selectedFuelType ?? CarFuelType.label,
        );

        List<int> calculatedCarEmissions = [];
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

        // **Calculate Emissions for Motorcycle**
        final motorcycleEmissionsCalculator = PrivateVehicleEmissionsCalculator(
          polylinesState: polylineState,
          vehicleSize: motorcycleState.selectedValue ?? MotorcycleSize.label,
        );

        List<int> calculatedMotorcycleEmissions = [];
        for (int i = 0; i < polylineState.distances.length; i++) {
          double emission = motorcycleEmissionsCalculator.calculateEmission(i);
          calculatedMotorcycleEmissions.add(emission.toInt());
        }

        motorcycleState.saveEmissions(calculatedMotorcycleEmissions);
        if (calculatedMotorcycleEmissions.isNotEmpty) {
          motorcycleState.updateMinEmission(calculatedMotorcycleEmissions.reduce(min));
          motorcycleState.updateMaxEmission(calculatedMotorcycleEmissions.reduce(max));
        }
      } catch (e) {
        // Handle errors if necessary
      }
    }).catchError((error) {
      // Handle errors if necessary
    });
  }
}






  void getUserLocationDetails() {
    final place = MapService().getAddressFromLatLng();

    place.then((placemark) {
      if (placemark != null) {
        setState(() {
         // _enableOriginForm = false;
        });
        final currentAddress =
            "${placemark.street!} ${placemark.locality!} ${placemark.postalCode!} ${placemark.country!}";
        originController.text = currentAddress;
      } else {
        _buildErrorWidget(
            "Address not found. Try entering an address manually");
      }
    });
    setUserMarker();
  }

  void setUserMarker() {
    final latLng = MapService().getUserLatLng();
    _addOriginMarker(latLng!); //Place the marker and save Lat and Lng to state
   // _enableDestForm = true;
  }
}