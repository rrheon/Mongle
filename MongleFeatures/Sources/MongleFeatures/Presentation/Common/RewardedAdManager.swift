#if os(iOS)
import GoogleMobileAds
import Observation
import UIKit

// MARK: - 보상형 광고 매니저 (하트 부족 시 사용)

@Observable
public final class RewardedAdManager: NSObject {
    public var isAdReady = false

    private var rewardedAd: GADRewardedAd?
    private var onEarnReward: (() -> Void)?

    public override init() {
        super.init()
        loadAd()
    }

    // MARK: - 광고 로드

    public func loadAd() {
        GADRewardedAd.load(
            withAdUnitID: AdConstants.rewardedAdUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            guard let self else { return }
            if let ad = ad {
                self.rewardedAd = ad
                ad.fullScreenContentDelegate = self
                self.isAdReady = true
            } else {
                self.isAdReady = false
            }
        }
    }

    // MARK: - 광고 재생

    /// - Parameter onEarnReward: 사용자가 광고를 끝까지 시청했을 때만 호출됨
    public func showAd(onEarnReward: @escaping () -> Void) {
        guard let ad = rewardedAd,
              let rootVC = UIApplication.shared
                .connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                .first
        else {
            loadAd()
            return
        }
        self.onEarnReward = onEarnReward
        ad.present(fromRootViewController: rootVC) { [weak self] in
            self?.onEarnReward?()
            self?.onEarnReward = nil
        }
        isAdReady = false
    }
}

// MARK: - GADFullScreenContentDelegate

extension RewardedAdManager: GADFullScreenContentDelegate {
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        loadAd() // 다음 광고 미리 로드
    }
}
#endif
