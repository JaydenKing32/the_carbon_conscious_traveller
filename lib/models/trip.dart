class Trip {
  int? id;
  String date;
  String origin;
  double origLat;
  double origLng;
  String destination;
  double destLat;
  double destLng;
  int distance;
  double emissions;
  String mode;
  double reduction;
  bool complete;
  String model;

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
    required this.reduction,
    required this.complete,
    required this.model,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'origin': origin,
      'origLat': origLat,
      'origLng': origLng,
      'destination': destination,
      'destLat': destLat,
      'destLng': destLng,
      'distance': distance,
      'emissions': emissions,
      'mode': mode,
      'reduction': reduction,
      'complete': complete ? 1 : 0,
      'model': model,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      date: map['date'],
      origin: map['origin'],
      origLat: map['origLat'] ?? 0.0,
      origLng: map['origLng'] ?? 0.0,
      destination: map['destination'],
      destLat: map['destLat'] ?? 0.0,
      destLng: map['destLng'] ?? 0.0,
      distance: map['distance'] ?? 0,
      emissions: map['emissions'],
      mode: map['mode'],
      reduction: map['reduction'] ?? 0.0,
      complete: (map['complete'] ?? 0) == 1,
      model: map['model'] ?? "",
    );
  }

  String distanceString() {
    if (distance >= 1000) {
      return "${(distance / 1000.0).toStringAsFixed(2)} km";
    } else {
      return "$distance m";
    }
  }
}
