import SwiftUI
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {
    var adUnitId: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitId
        banner.load(Request())
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
