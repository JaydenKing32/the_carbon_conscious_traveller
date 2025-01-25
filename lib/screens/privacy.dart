import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _hasAcceptedPolicy = false; // Tracks if user has accepted the policy

  @override
  void initState() {
    super.initState();
    _loadAcceptanceStatus();
  }

  // Load acceptance status from storage
  Future<void> _loadAcceptanceStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasAcceptedPolicy = prefs.getBool('acceptedPrivacyPolicy') ?? false;
    });
  }

  // Save acceptance status
  Future<void> _acceptPrivacyPolicy() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acceptedPrivacyPolicy', true);
    setState(() {
      _hasAcceptedPolicy = true;
    });
  }

  final String privacyText = """
**Privacy Policy**

**Last updated:** January 1, 2025

**Introduction**

Welcome to The Carbon Conscious Traveller (“TCCT”, “we”, “us”, or “our”). We are committed to protecting your personal information and your right to privacy. If you have any questions or concerns about this privacy notice, please contact us at support@tcctapp.com.

**Information We Collect**
- **Personal Data:** Name, email address, and other contact details.
- **Usage Data:** Information on how you use our app, including visited pages and interactions.
- **Device Information:** Model, operating system, and unique device identifiers.

**How We Use Your Data**
- To provide and improve our services.
- To analyze user behavior and optimize the app experience.
- To contact users for support and updates.

**Data Sharing**
We do not sell or share your personal data with third parties without your consent, except where required by law.

**User Rights**
You may have rights regarding your personal data, including access, correction, deletion, and data portability.

**Security Measures**
We implement reasonable security measures to protect your data but cannot guarantee absolute security.

**Changes to this Privacy Policy**
We may update this Privacy Policy periodically. Changes will be reflected here.

**Contact Us**
For questions, contact us at support@tcctapp.com.

**Consent**
By using our app, you agree to this Privacy Policy.
""";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: const Color.fromARGB(255, 7, 179, 110),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      "Privacy Policy",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),

                    // Last updated date
                    Text(
                      "Last updated: January 1, 2025",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Privacy policy content
                    RichText(
                      text: _buildPrivacyPolicyText(),
                    ),
                  ],
                ),
              ),
            ),

            // Accept Button Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasAcceptedPolicy
                      ? null // Disable the button if already accepted
                      : () async {
                          await _acceptPrivacyPolicy();
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("You have accepted the Privacy Policy."),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: _hasAcceptedPolicy ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _hasAcceptedPolicy ? "Privacy Policy Accepted" : "I Accept This Privacy Policy",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build formatted Privacy Policy text
  TextSpan _buildPrivacyPolicyText() {
    List<String> lines = privacyText.split('\n');

    List<TextSpan> spans = [];

    for (var line in lines) {
      if (line.startsWith('**') && line.endsWith('**')) {
        // Section Titles
        String title = line.replaceAll('**', '');
        spans.add(
          TextSpan(
            text: "$title\n\n",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      } else if (line.startsWith('**')) {
        // Subsection Titles
        String subtitle = line.replaceAll('**', '');
        spans.add(
          TextSpan(
            text: "$subtitle\n\n",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        );
      } else if (line.startsWith('*')) {
        // Bullet Points
        String bullet = line.replaceFirst('*', '•');
        spans.add(
          TextSpan(
            text: "$bullet ",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        );
      } else {
        // Regular Paragraph Text
        spans.add(
          TextSpan(
            text: "$line\n\n",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        );
      }
    }

    return TextSpan(children: spans, style: const TextStyle(color: Colors.black));
  }
}
