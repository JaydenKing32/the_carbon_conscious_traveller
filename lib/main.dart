import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/coordinates_state.dart';
import 'package:the_carbon_conscious_traveller/state/marker_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_car_state.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_motorcycle_state.dart';
import 'package:the_carbon_conscious_traveller/state/theme_state.dart';
import 'package:the_carbon_conscious_traveller/state/transit_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/bottom_sheet.dart';
import 'package:the_carbon_conscious_traveller/widgets/drawer.dart';
import 'package:the_carbon_conscious_traveller/widgets/google_map_view.dart';
import 'package:the_carbon_conscious_traveller/widgets/google_places_view.dart';
import 'package:the_carbon_conscious_traveller/state/settings_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings first
  final settings = Settings();
  await settings.loadPreferences();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MarkerState()),
        ChangeNotifierProvider(create: (context) => PolylinesState()),
        ChangeNotifierProvider(create: (context) => CoordinatesState()),
        ChangeNotifierProvider(create: (context) => PrivateMotorcycleState()),
        ChangeNotifierProvider(create: (context) => PrivateCarState()),
        ChangeNotifierProvider(create: (context) => TransitState()),
        ChangeNotifierProvider.value(
            value: settings), // Use pre-initialized settings
        ChangeNotifierProxyProvider4<PrivateMotorcycleState, PrivateCarState,
            TransitState, PolylinesState, ThemeState>(
          create: (context) => ThemeState(),
          update: (context, motorcycleState, carState, transitState,
              polylineState, themeState) {
            List<int> activeRouteEmissions = [];

            switch (polylineState.mode) {
              case 'motorcycling':
                activeRouteEmissions = motorcycleState.emissions;
                break;
              case 'driving':
                activeRouteEmissions = carState.emissions;
                break;
              case 'transit':
                activeRouteEmissions = transitState.emissions;
                break;
            }
            themeState!.updateTheme(activeRouteEmissions,
                polylineState.activeRouteIndex, polylineState.mode);
            return themeState;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeState>(builder: (context, themeState, child) {
      return MaterialApp(
        title: 'The Carbon-Conscious Traveller',
        theme: themeState.themeData,
        home: Consumer<Settings>(builder: (context, settings, child) {
          return const MyHomePage(
            title: 'The Carbon-Conscious Traveller',
          );
        }),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Stack(
          children: [
            GoogleMapView(),
            TravelModeBottomSheet(),
            GooglePlacesView(),
          ],
        ),
      ),
    );
  }
}
