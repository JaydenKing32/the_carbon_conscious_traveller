# The Carbon Conscious Traveller

## Setup Instructions

### Installation

1. **Clone the Repository:**
   ```sh
   git clone https://github.com/JaydenKing32/the_carbon_conscious_traveller.git
   cd yourproject

2. **Install Dependencies:**

    `flutter pub get`

3. **Configure Google Maps API Key:**

    You need to add your Google Maps API key to the `Config.plist` file for iOS and `local.properties` file for Android.

    **iOS:**
    * Create a file named Config.plist in the ios/Runner directory.
    * Add the following content to the Config.plist file, replacing    YOUR_GOOGLE_MAPS_API_KEY with your actual API key:

    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>GoogleMapsAPIKey</key>
        <string>YOUR_GOOGLE_MAPS_API_KEY</string>
    </dict>
    </plist>
    ```

    **Android**
    * Create a file named local.properties in the android/ directory of your project.
   * Append this line of code at the end:
        ```
        MAPS_API_KEY={YOUR_API_KEY}
        ```
        where `{YOUR_API_KEY}` is your generated API key.
