import SwiftUI
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {
    var adUnitId: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitId
        banner.load(GADRequest())
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
