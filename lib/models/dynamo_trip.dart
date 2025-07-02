class DynamoTrip {
  String deviceId;
  int tripId;
  String date;
  int distance;
  double emissions;
  double reduction;
  String mode;
  String model;

  DynamoTrip({
    required this.deviceId,
    required this.tripId,
    required this.date,
    required this.distance,
    required this.emissions,
    required this.reduction,
    required this.mode,
    required this.model,
  });
}
