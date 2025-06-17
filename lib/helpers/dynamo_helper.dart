import 'package:aws_dynamodb_api/dynamodb-2012-08-10.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_carbon_conscious_traveller/constants.dart';
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
      'device_id': AttributeValue(s: prefs.getString("deviceId")),
      'trip_id': AttributeValue(n: trip.id.toString()),
      'date': AttributeValue(s: trip.date),
      'origin': AttributeValue(s: trip.origin),
      'origLat': AttributeValue(n: trip.origLat.toStringAsFixed(4)),
      'origLng': AttributeValue(n: trip.origLng.toStringAsFixed(4)),
      'destination': AttributeValue(s: trip.destination),
      'destLat': AttributeValue(n: trip.destLat.toStringAsFixed(4)),
      'destLng': AttributeValue(n: trip.destLng.toStringAsFixed(4)),
      'distance': AttributeValue(n: trip.distance.toString()),
      'emissions': AttributeValue(n: trip.emissions.toStringAsFixed(4)),
      'reduction': AttributeValue(n: trip.reduction.toStringAsFixed(4)),
      'mode': AttributeValue(s: trip.mode),
      'model': AttributeValue(s: trip.model)
    };
  }

  static Future insertTrip(Trip? trip) async {
    if (trip != null) {
      debugPrint("adding trip $trip");
      await service.putItem(item: await tripToMap(trip), tableName: "tcct-trips");
    }
  }
}
