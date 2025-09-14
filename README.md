# Admin-charts

Sample SwiftUI project that displays Google AdMob earnings with charts and a home screen widget.

## Features
- Fetches AdMob earnings data with `AdMobService`.
- Charts earnings by app and ad unit.
- Filters for 1 day, 7 days, month and year.
- Home screen widget showing today's earnings.
- Banner ad at the bottom of the main screen.
- Light and dark mode friendly "bubbly" UI with shadows.

## Building
1. Open `Admob Earn.xcodeproj` in Xcode 15 or later.
2. Add the [Google Mobile Ads SDK](https://github.com/googleads/swift-package-manager-google-mobile-ads) via Swift Package Manager.
3. Provide a valid AdMob access token in `AdMobService` and your banner `adUnitId` in `ContentView`.
4. Run the app on iOS 16 or later.

Widget targets require enabling the widget extension in Xcode.
