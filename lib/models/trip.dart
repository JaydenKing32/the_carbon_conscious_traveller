class Trip {
  int? id;
  String date;
  String origin;
  double origLat; // Added
  double origLng; // Added
  String destination;
  double destLat; // Added
  double destLng; // Added
  String distance;
  double emissions;
  String mode;

  Trip({
    this.id,
    required this.date,
    required this.origin,
    required this.origLat,
    required this.origLng,
    required this.destination,
    required this.destLat,
    required this.destLng,
    required this.distance,
    required this.emissions,
    required this.mode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'origin': origin,
      'origLat': origLat, // Added
      'origLng': origLng, // Added
      'destination': destination,
      'destLat': destLat, // Added
      'destLng': destLng, // Added
      'distance': distance,
      'emissions': emissions,
      'mode': mode,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      date: map['date'],
      origin: map['origin'],
      origLat: map['origLat'] ?? 0.0, // Added
      origLng: map['origLng'] ?? 0.0, // Added
      destination: map['destination'],
      destLat: map['destLat'] ?? 0.0, // Added
      destLng: map['destLng'] ?? 0.0, // Added
      distance: map['distance'],
      emissions: map['emissions'],
      mode: map['mode'],
    );
  }
}
