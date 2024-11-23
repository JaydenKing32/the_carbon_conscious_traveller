import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_directions_api/google_directions_api.dart' as dir;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:the_carbon_conscious_traveller/constants.dart';
import 'package:the_carbon_conscious_traveller/helpers/map_service.dart';
import 'package:the_carbon_conscious_traveller/state/marker_state.dart';
import 'package:the_carbon_conscious_traveller/state/coordinates_state.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/models/routes_model.dart';
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
  bool _enableOriginForm = true; // Origin textfield state
  bool _enableDestForm = false; // Destination textfield state

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
                enabled: _enableOriginForm,
                onTapOutside: (PointerDownEvent event) {
                  setState(() {
                    //hide the keyboard when the user taps outside the textfield
                    FocusScope.of(context).unfocus();
                  });
                },
                onChanged: (value) => _onPredictTextChanged(value, "start"),
                decoration: InputDecoration(
                    label: Text("Enter a start location"),
                    icon: Icon(Icons.location_searching_outlined,
                        color: Colors.grey),
                    suffixIcon:
                        LocationButton(callback: getUserLocationDetails)),
              ),
              TextFormField(
                controller: destinationController,
                onTapOutside: (PointerDownEvent event) {
                  setState(() {
                    //hide the keyboard when the user taps outside the textfield
                    FocusScope.of(context).unfocus();
                  });
                },
                enabled: _enableDestForm,
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
      final result =
          await _places.fetchPlace(item.placeId, fields: _placeFields);

      if (fieldType == "start") {
        originController.text = item.fullText;

        setState(() {
          origin = result.place;
          _fetchingPlace = false;
          originLatLng = origin?.latLng;
          _addOriginMarker(LatLng(originLatLng!.lat, originLatLng!.lng));
          _enableOriginForm = false;
          _enableDestForm = true;
          _predictions = [];
        });
        if (mounted) {
          MapService().goToLocation(
              context, LatLng(originLatLng!.lat, originLatLng!.lng));
        }
      } else if (fieldType == "destination") {
        destinationController.text = item.fullText;
        setState(() {
          destination = result.place;
          _fetchingPlace = false;
          destinationLatLng = destination?.latLng;
          _addDestinationMarker(
              LatLng(destinationLatLng!.lat, destinationLatLng!.lng));
          _enableDestForm = false;
          _predictions = [];
          final polylineState =
              Provider.of<PolylinesState>(context, listen: false);
          if (polylineState.mode == "") {
            polylineState.transportMode = "driving";
          } else {
            polylineState.transportMode = polylineState.mode;
          }
        });
        if (mounted) {
          MapService().goToLocation(
              context, LatLng(destinationLatLng!.lat, destinationLatLng!.lng));
        }
      }
    } catch (err) {
      setState(() {
        _fetchingPlaceErr = err;
        _fetchingPlace = false;
      });
    }
  }

  void _addOriginMarker(LatLng originLatLng) {
    LatLng position = originLatLng;
    final markerModel = Provider.of<MarkerState>(context, listen: false);
    markerModel.addMarker(LatLng(position.latitude, position.longitude));

    final coordinatesModel =
        Provider.of<CoordinatesState>(context, listen: false);
    coordinatesModel
        .saveOriginCoords(LatLng(position.latitude, position.longitude));
  }

  void _addDestinationMarker(LatLng destinationLatLng) {
    LatLng position = destinationLatLng;

    final markerState = Provider.of<MarkerState>(context, listen: false);
    markerState.addMarker(
      LatLng(position.latitude, position.longitude),
    );

    final coordsState = Provider.of<CoordinatesState>(context, listen: false);
    coordsState.saveDestinationCoords(
      LatLng(position.latitude, position.longitude),
    );

    final polylineState = Provider.of<PolylinesState>(context, listen: false);
    polylineState.getPolyline(coordsState.coordinates);
  }

  void getUserLocationDetails() {
    final place = MapService().getAddressFromLatLng();

    place.then((placemark) {
      if (placemark != null) {
        setState(() {
          _enableOriginForm = false;
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
    _enableDestForm = true;
  }
}
