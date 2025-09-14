# Admin-charts

Sample SwiftUI project that displays Google AdMob earnings with charts and a home screen widget.

## Features
- Fetches AdMob earnings data with `AdMobService`.
- Charts earnings by app and ad unit.
- Filters for 1 day, 7 days, month and year.
- Home screen widget showing today's earnings.
- Light and dark mode friendly "bubbly" UI with shadows.

## Building
1. Open `Admob Earn.xcodeproj` in Xcode 15 or later.
2. Configure OAuth2 credentials (see below) and update `OAuth2Manager` with your client ID and redirect URI.
3. Run the app on iOS 16 or later.

Widget targets require enabling the widget extension in Xcode.

## OAuth2 Setup
1. In the [Google Cloud Console](https://console.cloud.google.com/), create a project and enable the AdMob API.
2. Create an OAuth 2.0 Client ID of type **iOS** using your app's bundle identifier.
3. Add a redirect URI matching a custom URL scheme, e.g. `com.example.app:/oauth2redirect`.
4. In Xcode, register the same URL scheme under **Info > URL Types**.
5. Replace `YOUR_CLIENT_ID` and `YOUR_REDIRECT_URI` in `OAuth2Manager.swift` with the values from the console.
6. Build and run. The app will prompt you to sign in and request `admob.readonly` scope to retrieve earnings.
