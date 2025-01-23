import 'package:flutter/material.dart';
import 'package:the_carbon_conscious_traveller/screens/privacy.dart';
import 'package:the_carbon_conscious_traveller/screens/settings.dart';
import 'package:the_carbon_conscious_traveller/screens/trips_screen.dart';
import 'package:the_carbon_conscious_traveller/screens/stat.dart';
import 'package:the_carbon_conscious_traveller/screens/about.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          TextButton(
            child: const Row(
              children: [Icon(Icons.info_outline_rounded), Text(' About')],
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          TextButton(
            child: const Row(
              children: [Icon(Icons.history_outlined), Text(' Trips')],
            ),
            onPressed: () {
              Navigator.of(context).push(
                 MaterialPageRoute(builder: (context) => const TripsScreen()),
              );
            },
          ),
          TextButton(
            child: const Row(
              children: [Icon(Icons.show_chart_outlined), Text(' Statistics')],
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const StatisticsScreen()),
              );
            },
          ),
          TextButton(
            child: const Row(
              children: [Icon(Icons.privacy_tip_outlined), Text(' Privacy')],
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
          TextButton(
            child: const Row(
              children: [Icon(Icons.settings_outlined), Text(' Settings')],
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

