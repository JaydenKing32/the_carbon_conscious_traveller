import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchGitHub() async {
    final Uri url = Uri.parse("https://github.com/JaydenKing32/the_carbon_conscious_traveller.git");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchSupportEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'the.carbon.conscious.traveller@gmail.com',
      query: 'subject=Support Request',
    );
    if (!await launchUrl(emailUri)) {
      throw Exception('Could not launch email client');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "The Carbon-Conscious Traveller",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "TCCT helps travellers track and reduce their carbon footprint. "
                      "It calculates carbon emissions based on vehicle type, size, and fuel, "
                      "offering eco-friendly travel alternatives with real-time tracking and visualization.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Key Features",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _featureItem(context, "🌍 Carbon Emission Tracking", "See emissions for each trip."),
                    _featureItem(context, "🗺️ Multiple Route Options", "Choose routes with lower emissions."),
                    _featureItem(context, "🌲 Tree Offset Calculation", "Find out how many trees offset your trip."),
                    _featureItem(context, "🚗 Custom Vehicle Settings", "Set car type, size & fuel type."),
                    _featureItem(context, "📊 Visual Carbon Stats", "Track emissions with charts & fun facts."),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.support_agent),
                      label: const Text("Contact Support"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _launchSupportEmail,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.code),
                      label: const Text("View on GitHub"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _launchGitHub,
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              "Developers",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: const Row(spacing: 30, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Jayden King"), Text("Isac Kim"), Text("Ngoc Nguyen")]),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Paola Reategui"),
                    Text("Svyatoslav Kushnarev"),
                    Text("Young Choon Lee"),
                  ])
                ]))
          ],
        ),
      ),
    );
  }

  Widget _featureItem(BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: "$title\n",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                children: [
                  TextSpan(
                    text: description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
