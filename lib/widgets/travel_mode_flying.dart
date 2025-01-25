// flying.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
// Ensure the import path for Constants and Flight is correct
import 'package:the_carbon_conscious_traveller/constants.dart';
import 'package:the_carbon_conscious_traveller/data/flight.dart';
// Corrected the import path from 'emisson.dart' to 'emission_dialog.dart'
import 'dart:convert';

import 'package:the_carbon_conscious_traveller/widgets/emisson.dart';

class Flying extends StatefulWidget {
  const Flying({super.key});

  @override
  State<Flying> createState() => _FlyingState();
}

class _FlyingState extends State<Flying> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _airlineController = TextEditingController();
  final TextEditingController _flightNumberController = TextEditingController();
  final TextEditingController _departureDateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  ResponseBody? _responseBody;
  String? _errorMessage;

  // Replace with your actual API key securely
  final String _apiKey = Constants.fApiKey;

  // Regex patterns
  final List<RegExp> _regexes = [
    RegExp(r'^[a-zA-Z]{3}$'), // Origin Airport
    RegExp(r'^[a-zA-Z]{3}$'), // Destination Airport
    RegExp(r'^(\d|[a-zA-Z]){2}$'), // Operating Carrier Code
    RegExp(r'^\d{1,4}$'), // Flight Number
  ];

  final List<String> _errorMessages = [
    "Airport code must consist of 3 letters",
    "Airport code must consist of 3 letters",
    "Operating carrier code must consist of 2 alphanumerics",
    "Flight number must consist of 1 to 4 digits",
  ];

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _airlineController.dispose();
    _flightNumberController.dispose();
    _departureDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDepartureDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(), // DateValidatorPointForward.now()
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _departureDateController.text = DateFormat.yMd().format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _responseBody = null;
      _errorMessage = null;
    });

    // Ensure no extra characters like ":" in the airport codes
    String origin = _originController.text.toUpperCase().replaceAll(':', '').trim();
    String destination = _destinationController.text.toUpperCase().replaceAll(':', '').trim();

    RequestBody requestBody = RequestBody(flights: [
      Flight(
        origin: origin,
        destination: destination,
        operatingCarrierCode: _airlineController.text.toUpperCase().trim(),
        flightNumber: int.parse(_flightNumberController.text),
        departureDate: DateModel(
          year: _selectedDate.year,
          month: _selectedDate.month,
          day: _selectedDate.day,
        ),
      ),
    ]);

    final String requestURL =
        "https://travelimpactmodel.googleapis.com/v1/flights:computeFlightEmissions?key=$_apiKey";

    try {
      final response = await http.post(
        Uri.parse(requestURL),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode(requestBody.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _responseBody = ResponseBody.fromJson(responseData);
        });

        if (_responseBody?.flightEmissions != null &&
            _responseBody!.flightEmissions!.isNotEmpty) {
          // Assuming you're displaying emissions for the first flight
          final emissions = _responseBody!.flightEmissions![0].emissionsGramsPerPax;
          _showEmissionsDialog(emissions);
        } else {
          setState(() {
            _errorMessage = "No emission data received.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Error.  \n Check the entered data again!";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error. \n Check the entered data again!";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showEmissionsDialog(Emissions emissions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EmissionDialog(
          emissions: emissions,
          onCalculateAgain: () {
            Navigator.of(context).pop(); // Close the dialog
            _formKey.currentState!.reset(); // Reset the form
            _originController.clear();
            _destinationController.clear();
            _airlineController.clear();
            _flightNumberController.clear();
            _departureDateController.clear();
          },
        );
      },
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtain screen size for responsive text scaling
    double screenWidth = MediaQuery.of(context).size.width;

    // Determine base font size based on screen width
    double baseFontSize = screenWidth > 600 ? 20 : 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flying Emission Calculator'),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          width: 600,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  "Flight Emission Calculator",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Origin Airport
                      TextFormField(
                        controller: _originController,
                        decoration: const InputDecoration(
                          labelText: "Origin Airport (3 letters)",
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null ||
                              !_regexes[0]
                                  .hasMatch(value.toUpperCase().replaceAll(':', '').trim())) {
                            return _errorMessages[0];
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Destination Airport
                      TextFormField(
                        controller: _destinationController,
                        decoration: const InputDecoration(
                          labelText: "Destination Airport (3 letters)",
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null ||
                              !_regexes[1]
                                  .hasMatch(value.toUpperCase().replaceAll(':', '').trim())) {
                            return _errorMessages[1];
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Operating Carrier Code
                      TextFormField(
                        controller: _airlineController,
                        decoration: const InputDecoration(
                          labelText: "Operating Carrier Code (2 alphanumerics)",
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null ||
                              !_regexes[2].hasMatch(value.toUpperCase().trim())) {
                            return _errorMessages[2];
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Flight Number
                      TextFormField(
                        controller: _flightNumberController,
                        decoration: const InputDecoration(
                          labelText: "Flight Number (1-4 digits)",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || !_regexes[3].hasMatch(value)) {
                            return _errorMessages[3];
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Departure Date
                      TextFormField(
                        controller: _departureDateController,
                        decoration: const InputDecoration(
                          labelText: "Departure Date",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDepartureDate(context),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: TextStyle(fontSize: baseFontSize),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Calculate Emissions"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildErrorMessage(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
