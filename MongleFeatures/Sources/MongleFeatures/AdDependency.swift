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
import Foundation
import GoogleMobileAds
import UIKit

extension AdClient {
    static let live = AdClient(
        showRewardedAd: {
            // AdMob SDK 초기화 완료를 먼저 기다린다.
            // 사용자가 초기화 전에 버튼을 누르면 load 가 실패하기 때문.
            await MobileAdsInitializer.shared.waitUntilStarted()

            // 프리로드된 광고가 있으면 즉시 재생, 없으면 여기서 load → 재생.
            return await RewardedAdLoader.shared.showAd()
        }
    )
}

// MARK: - AdMob SDK 초기화 (1회성)

/// `GADMobileAds.sharedInstance().start(...)` 완료를 추적하기 위한 헬퍼.
/// `ConsentManager` 가 한 번 초기화를 트리거하면, 이후 모든 광고 요청은
/// `waitUntilStarted()` 로 준비 완료를 기다렸다가 실행된다.
public final class MobileAdsInitializer: @unchecked Sendable {
    public static let shared = MobileAdsInitializer()

    private let lock = NSLock()
    private var isStarted = false
    private var isStarting = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    private init() {}

    /// ConsentManager 에서 한 번 호출한다. 여러 번 호출해도 안전.
    public func startIfNeeded() {
        lock.lock()
        if isStarted || isStarting {
            lock.unlock()
            return
        }
        isStarting = true
        lock.unlock()

        DispatchQueue.main.async {
            GADMobileAds.sharedInstance().start { [weak self] _ in
                self?.markStarted()
            }
        }
    }

    private func markStarted() {
        lock.lock()
        isStarted = true
        isStarting = false
        let pending = waiters
        waiters.removeAll()
        lock.unlock()

        for w in pending { w.resume() }
    }

    /// SDK 초기화가 끝날 때까지 suspend. 이미 완료됐다면 즉시 리턴.
    public func waitUntilStarted() async {
        lock.lock()
        if isStarted {
            lock.unlock()
            return
        }
        // 아직 start 가 호출되지 않았으면 여기서라도 트리거.
        let needTrigger = !isStarting
        if needTrigger { isStarting = true }
        lock.unlock()

        if needTrigger {
            DispatchQueue.main.async { [weak self] in
                GADMobileAds.sharedInstance().start { _ in
                    self?.markStarted()
                }
            }
        }

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            lock.lock()
            if isStarted {
                lock.unlock()
                cont.resume()
            } else {
                waiters.append(cont)
                lock.unlock()
            }
        }
    }
}

// MARK: - 보상형 광고 프리로더 (싱글톤)

/// 싱글톤으로 rewarded ad 를 미리 load 해두고, 재생 후 자동으로 다음 광고를 다시 load.
/// 이렇게 하면 사용자가 "광고 보고 하트 받기" 를 눌렀을 때 체감 지연이 없고,
/// 일시적인 로드 실패가 있어도 다음 요청에서 회복된다.
final class RewardedAdLoader: NSObject, @unchecked Sendable {
    static let shared = RewardedAdLoader()

    private let lock = NSLock()
    private var ad: GADRewardedAd?
    private var isLoading = false
    private var activeDelegate: RewardedAdDelegate?

    private override init() {
        super.init()
        // 앱 시작 시 미리 한 번 로드.
        Task { @MainActor in
            await MobileAdsInitializer.shared.waitUntilStarted()
            self.preload()
        }
    }

    /// 외부에서 초기 preload 트리거 (ConsentManager 초기화 이후 호출 가능).
    func preload() {
        lock.lock()
        if ad != nil || isLoading {
            lock.unlock()
            return
        }
        isLoading = true
        lock.unlock()

        DispatchQueue.main.async {
            GADRewardedAd.load(
                withAdUnitID: AdConstants.rewardedAdUnitID,
                request: GADRequest()
            ) { [weak self] loaded, error in
                guard let self else { return }
                self.lock.lock()
                self.isLoading = false
                if let loaded {
                    self.ad = loaded
                } else {
                    #if DEBUG
                    if let error {
                        print("[Ad] rewarded load failed: \(error.localizedDescription)")
                    }
                    #endif
                    self.ad = nil
                }
                self.lock.unlock()
            }
        }
    }

    /// 프리로드된 광고를 재생한다. 없으면 즉석에서 load → 재생 시도.
    /// - Returns: 사용자가 보상을 획득했는지 여부
    @MainActor
    func showAd() async -> Bool {
        await MobileAdsInitializer.shared.waitUntilStarted()

        // 1) 프리로드된 광고가 있으면 바로 재생
        lock.lock()
        var current = self.ad
        self.ad = nil
        lock.unlock()

        // 2) 없으면 즉석에서 한 번 load 시도 (타임아웃 8초)
        if current == nil {
            current = await loadOnce()
        }

        guard let ad = current else {
            // 다음 사용을 위해 백그라운드 재시도
            preload()
            return false
        }

        guard let rootVC = Self.topViewController() else {
            #if DEBUG
            print("[Ad] no root view controller to present")
            #endif
            // 다음 사용을 위해 백그라운드 재시도
            preload()
            return false
        }

        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            let delegate = RewardedAdDelegate { [weak self] earned in
                cont.resume(returning: earned)
                // 다음 광고 미리 로드
                self?.activeDelegate = nil
                self?.preload()
            }
            self.activeDelegate = delegate
            ad.fullScreenContentDelegate = delegate

            ad.present(fromRootViewController: rootVC) {
                delegate.didEarnReward = true
            }
        }
    }

    /// 1회성 ad load. 타임아웃 포함.
    private func loadOnce() async -> GADRewardedAd? {
        await withCheckedContinuation { (cont: CheckedContinuation<GADRewardedAd?, Never>) in
            var didResume = false
            let resumeLock = NSLock()
            let safeResume: (GADRewardedAd?) -> Void = { result in
                resumeLock.lock()
                defer { resumeLock.unlock() }
                guard !didResume else { return }
                didResume = true
                cont.resume(returning: result)
            }

            DispatchQueue.main.async {
                GADRewardedAd.load(
                    withAdUnitID: AdConstants.rewardedAdUnitID,
                    request: GADRequest()
                ) { loaded, error in
                    if let error {
                        #if DEBUG
                        print("[Ad] rewarded load (on-demand) failed: \(error.localizedDescription)")
                        #endif
                    }
                    safeResume(loaded)
                }
            }

            // 8초 타임아웃
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                safeResume(nil)
            }
        }
    }

    // MARK: - Top VC helper (iOS 15+ 권장 방식)

    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root: UIViewController? = base ?? {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                ?? scenes.first { $0 is UIWindowScene } as? UIWindowScene
            return windowScene?.windows.first { $0.isKeyWindow }?.rootViewController
                ?? windowScene?.windows.first?.rootViewController
        }()

        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }
        return root
    }
}

// MARK: - Delegate 브릿지

private final class RewardedAdDelegate: NSObject, GADFullScreenContentDelegate, @unchecked Sendable {
    private let onFinish: (Bool) -> Void
    var didEarnReward = false
    private var didFinish = false
    private let finishLock = NSLock()

    init(onFinish: @escaping (Bool) -> Void) {
        self.onFinish = onFinish
    }

    private func finishOnce(_ earned: Bool) {
        finishLock.lock()
        defer { finishLock.unlock() }
        guard !didFinish else { return }
        didFinish = true
        onFinish(earned)
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        finishOnce(didEarnReward)
    }

    func ad(_ ad: GADFullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        #if DEBUG
        print("[Ad] failed to present: \(error.localizedDescription)")
        #endif
        finishOnce(false)
    }
}
#endif

// MARK: - Stub (macOS / Preview / Test)

extension AdClient {
    static let stub = AdClient(showRewardedAd: { false })
}
