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
    private let topPadding: CGFloat
    private let bottomPadding: CGFloat
    private let horizontalPadding: CGFloat

    public init(
        top: CGFloat = 0,
        bottom: CGFloat = 0,
        horizontal: CGFloat = 0
    ) {
        self.topPadding = top
        self.bottomPadding = bottom
        self.horizontalPadding = horizontal
    }

    public var body: some View {
        // 서버 /config (MG-132) — 비활성 시 layout 공간도 차지하지 않도록 EmptyView 반환.
        // padding 은 호출자가 외부 modifier 로 붙이면 ModifiedContent 가 항상 emit 되어
        // 부모 VStack 의 자식 슬롯이 잡혀 빈 공간이 남는다. 그래서 padding 도 본 구조체가
        // 인자로 받아 if 블록 안에서 적용 — Android 의 early return 과 동일한 효과 (MG-139).
        if AdConfigStore.isAdEnabled {
            VStack(alignment: .leading, spacing: 8) {
                AdBannerView()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#F5F5F5"))
                    .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            }
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .padding(.horizontal, horizontalPadding)
        }
    }
}
#endif
