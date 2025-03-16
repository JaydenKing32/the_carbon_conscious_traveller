class DateModel {
  final int year;
  final int month;
  final int day;

  DateModel({required this.year, required this.month, required this.day});

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'day': day,
      };
}

class Flight {
  final String origin;
  final String destination;
  final String operatingCarrierCode;
  final int flightNumber;
  final DateModel departureDate;

  Flight({
    required this.origin,
    required this.destination,
    required this.operatingCarrierCode,
    required this.flightNumber,
    required this.departureDate,
  });

  Map<String, dynamic> toJson() => {
        'origin': origin,
        'destination': destination,
        'operatingCarrierCode': operatingCarrierCode,
        'flightNumber': flightNumber,
        'departureDate': departureDate.toJson(),
      };
}

class RequestBody {
  final List<Flight> flights;

  RequestBody({required this.flights});

  Map<String, dynamic> toJson() => {
        'flights': flights.map((flight) => flight.toJson()).toList(),
      };
}

class Emissions {
  final double first;
  final double business;
  final double premiumEconomy;
  final double economy;

  Emissions({
    required this.first,
    required this.business,
    required this.premiumEconomy,
    required this.economy,
  });

  factory Emissions.fromJson(Map<String, dynamic> json) {
    return Emissions(
      first: (json['first'] ?? 0).toDouble(),
      business: (json['business'] ?? 0).toDouble(),
      premiumEconomy: (json['premiumEconomy'] ?? 0).toDouble(),
      economy: (json['economy'] ?? 0).toDouble(),
    );
  }
}

class FlightEmission {
  final Emissions emissionsGramsPerPax;

  FlightEmission({required this.emissionsGramsPerPax});

  factory FlightEmission.fromJson(Map<String, dynamic> json) {
    return FlightEmission(
      emissionsGramsPerPax: Emissions.fromJson(json['emissionsGramsPerPax']),
    );
  }
}

class ResponseBody {
  final List<FlightEmission>? flightEmissions;

  ResponseBody({this.flightEmissions});

  factory ResponseBody.fromJson(Map<String, dynamic> json) {
    if (json['flightEmissions'] != null) {
      var list = json['flightEmissions'] as List;
      return ResponseBody(
        flightEmissions: list.map((e) => FlightEmission.fromJson(e)).toList(),
      );
    }
    return ResponseBody(flightEmissions: null);
  }
}
