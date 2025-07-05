import 'package:aws_dynamodb_api/dynamodb-2012-08-10.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_carbon_conscious_traveller/constants.dart';
import 'package:the_carbon_conscious_traveller/models/dynamo_trip.dart';
import 'package:the_carbon_conscious_traveller/models/trip.dart';

// https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/getting-started-step-1.html
// https://pub.dev/packages/aws_dynamodb_api
// https://pub.dev/documentation/aws_dynamodb_api/latest/dynamodb-2012-08-10/DynamoDB-class.html
// https://stackoverflow.com/a/73748312
class DynamoHelper {
  static final service = DynamoDB(region: "ap-southeast-2", credentials: AwsClientCredentials(accessKey: Constants.aws_key, secretKey: Constants.aws_secret));

  static Future<Map<String, AttributeValue>> tripToMap(Trip trip) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "device_id": AttributeValue(s: prefs.getString("deviceId")),
      "trip_id": AttributeValue(n: trip.id.toString()),
      "date": AttributeValue(s: trip.date),
      "distance": AttributeValue(n: trip.distance.toString()),
      "emissions": AttributeValue(n: trip.emissions.toStringAsFixed(4)),
      "reduction": AttributeValue(n: trip.reduction.toStringAsFixed(4)),
      "mode": AttributeValue(s: trip.mode),
      "model": AttributeValue(s: trip.model)
    };
  }

  static DynamoTrip mapToDynamoTrip(Map<String, AttributeValue> map) {
    return DynamoTrip(
      deviceId: map["device_id"]?.s ?? "",
      tripId: map["trip_id"]?.n != null ? int.parse(map["trip_id"]!.n!) : 0,
      date: map["date"]?.s ?? "",
      distance: map["distance"]?.n != null ? int.parse(map["distance"]!.n!) : 0,
      emissions: map["emissions"]?.n != null ? double.parse(map["emissions"]!.n!) : 0,
      reduction: map["reduction"]?.n != null ? double.parse(map["reduction"]!.n!) : 0,
      mode: map["mode"]?.s ?? "",
      model: map["model"]?.s ?? "",
    );
  }

  static Future insertTrip(Trip? trip) async {
    final event = (await SharedPreferences.getInstance()).getString("event");
    if (trip != null && event != null) {
      debugPrint("adding trip $trip");
      await service.putItem(item: await tripToMap(trip), tableName: event);
    }
  }

  static Future<List<DynamoTrip>> getTrips() async {
    final event = (await SharedPreferences.getInstance()).getString("event");

    if (event != null) {
      final scanResult = await service.scan(tableName: event);
      return scanResult.items?.map(mapToDynamoTrip).toList() ?? List.empty();
    } else {
      return List.empty();
    }
  }

  static Future<List<String>> getEvents() async {
    final scanResult = await service.scan(tableName: "tcct-events");
    final events = scanResult.items?.map((map) => map["event"]?.s ?? "").toList() ?? List.empty();
    events.remove("");
    return events;
  }
}
