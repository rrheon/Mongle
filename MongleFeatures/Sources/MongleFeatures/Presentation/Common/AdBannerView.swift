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
        // 서버 /config (MG-132) — 비활성 시 layout 공간도 차지하지 않도록 EmptyView 반환.
        // 호출자 (Settings/Home/History 등) 의 분기 코드는 불필요.
        if AdConfigStore.isAdEnabled {
            VStack(alignment: .leading, spacing: 8) {
                AdBannerView()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#F5F5F5"))
                    .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            }
        }
    }
}
#endif
