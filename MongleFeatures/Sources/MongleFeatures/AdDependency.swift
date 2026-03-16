import ComposableArchitecture

// MARK: - AdClient (TCA Dependency)

struct AdClient: Sendable {
    /// 보상형 광고를 재생하고, 사용자가 끝까지 시청하면 true를 반환합니다.
    var showRewardedAd: @Sendable () async -> Bool
}

// MARK: - DependencyKey

private enum AdClientKey: DependencyKey {
    static var liveValue: AdClient {
        #if os(iOS)
        return .live
        #else
        return .stub
        #endif
    }

    static let testValue = AdClient.stub
}

extension DependencyValues {
    var adClient: AdClient {
        get { self[AdClientKey.self] }
        set { self[AdClientKey.self] = newValue }
    }
}

// MARK: - Live Implementation (iOS)

#if os(iOS)
import GoogleMobileAds
import UIKit

extension AdClient {
    static let live = AdClient(
        showRewardedAd: {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    // 광고 로드 (callback 방식)
                    GADRewardedAd.load(
                        withAdUnitID: AdConstants.rewardedAdUnitID,
                        request: GADRequest()
                    ) { ad, error in
                        guard let ad = ad else {
                            continuation.resume(returning: false)
                            return
                        }

                        // Root ViewController 획득
                        guard let rootVC = UIApplication.shared
                            .connectedScenes
                            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                            .first
                        else {
                            continuation.resume(returning: false)
                            return
                        }

                        // 딜리게이트: 광고 종료 시 continuation 완료
                        let delegate = RewardedAdDelegate(continuation: continuation)
                        ad.fullScreenContentDelegate = delegate

                        // 광고 재생 — 끝까지 시청 시 rewardHandler 호출
                        ad.present(fromRootViewController: rootVC) {
                            delegate.didEarnReward = true
                        }
                    }
                }
            }
        }
    )
}

// MARK: - Delegate 브릿지

private final class RewardedAdDelegate: NSObject, GADFullScreenContentDelegate, @unchecked Sendable {
    private let continuation: CheckedContinuation<Bool, Never>
    var didEarnReward = false

    init(continuation: CheckedContinuation<Bool, Never>) {
        self.continuation = continuation
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        continuation.resume(returning: didEarnReward)
    }

    func ad(_ ad: GADFullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        continuation.resume(returning: false)
    }
}
#endif

// MARK: - Stub (macOS / Preview / Test)

extension AdClient {
    static let stub = AdClient(showRewardedAd: { false })
}
