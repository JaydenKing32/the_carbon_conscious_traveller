import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_carbon_conscious_traveller/models/coordinates_state.dart';
import 'package:the_carbon_conscious_traveller/models/marker_state.dart';
import 'package:the_carbon_conscious_traveller/models/private_car_state.dart';
import 'package:the_carbon_conscious_traveller/models/polylines_state.dart';
import 'package:the_carbon_conscious_traveller/models/private_motorcycle_state.dart';
import 'package:the_carbon_conscious_traveller/widgets/drawer.dart';
import 'package:the_carbon_conscious_traveller/widgets/google_map_view.dart';
import 'package:the_carbon_conscious_traveller/widgets/google_places_view.dart';
import 'package:the_carbon_conscious_traveller/widgets/test_directions.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MarkerState()),
        ChangeNotifierProvider(create: (context) => PolylinesState()),
        ChangeNotifierProvider(create: (context) => CoordinatesState()),
        ChangeNotifierProvider(create: (context) => PrivateMotorcycleState()),
        ChangeNotifierProvider(create: (context) => PrivateCarState()),
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
      title: 'The Carbon Concious Traveller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 7, 179, 110)),
        primaryColor: const Color.fromARGB(255, 7, 179, 110),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 24),
          bodyMedium: TextStyle(fontSize: 16),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'The Carbon Concious Traveller',
      ),
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
            GooglePlacesView(),
            //TestDirections(),
          ],
        ),
      ),
    );
  }
}
