import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/state/coordinates_state.dart';
import 'package:the_carbon_conscious_traveller/state/marker_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_car_state.dart';
import 'package:the_carbon_conscious_traveller/state/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/state/private_motorcycle_state.dart';
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
        ChangeNotifierProvider.value(value: settings), // Use pre-initialized settings
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Carbon-Conscious Traveller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 7, 179, 110)),
        primaryColor: const Color.fromARGB(255, 7, 179, 110),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 24),
          displayMedium: TextStyle(fontSize: 20),
          displaySmall: TextStyle(fontSize: 16),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          bodySmall: TextStyle(
            fontSize: 13,
            color: Color.fromARGB(255, 125, 125, 125),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
      ),
      home: Consumer<Settings>(builder: (context, settings, child) {
        return const MyHomePage(
          title: 'The Carbon-Conscious Traveller',
        );
      }),
      debugShowCheckedModeBanner: false,
    );
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
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
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
