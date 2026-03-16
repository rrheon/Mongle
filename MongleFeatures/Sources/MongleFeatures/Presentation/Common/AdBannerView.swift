#if os(iOS)
import SwiftUI
import GoogleMobileAds

// MARK: - 광고 배너 (Settings · Home · History 공용)

public struct AdBannerView: UIViewRepresentable {
    public init() {}

    public func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner) // 320×50
        banner.adUnitID = AdConstants.bannerAdUnitID
        banner.rootViewController = UIApplication.shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        banner.load(GADRequest())
        return banner
    }

    public func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

// MARK: - 배너 섹션 레이아웃 (Settings 화면의 "후원" 섹션과 동일한 스타일)

public struct AdBannerSection: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("후원")
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)
                .padding(.horizontal, MongleSpacing.xxs)

            AdBannerView()
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "#F5F5F5"))
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
        }
    }
}
#endif
