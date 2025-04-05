import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Read API key from Config.plist
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
      if let config = NSDictionary(contentsOfFile: path),
         let apiKey = config["GoogleMapsAPIKey"] as? String {
        GMSServices.provideAPIKey(apiKey)
      } else {
        fatalError("Google Maps API key not found in Config.plist")
      }
    } else {
      fatalError("Config.plist file not found")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
