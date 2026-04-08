//
//  ConsentManager.swift
//  MongleFeatures
//
//  Google UMP (User Messaging Platform) SDK 래퍼.
//  GDPR(EEA/UK) · CCPA/CPRA(US) 등 동의 수집이 필요한 지역에서 AdMob 개인화 광고 전
//  동의 팝업을 표시한다. 한국·일본 사용자에 대해서는 UMP 흐름을 건너뛰고 AdMob 을 즉시
//  초기화한다 (해당 지역은 UMP 동의 요구 대상이 아니며, 불필요한 네트워크 호출/지연을 방지).
//

#if os(iOS)
import Foundation
import UIKit
import AppTrackingTransparency
import AdSupport
import GoogleMobileAds
import UserMessagingPlatform

/// 앱 실행 직후 동의 수집 흐름을 관리하는 싱글톤.
/// 지역 판정 → (필요 시) UMP 폼 표시 → AdMob 초기화 순으로 동작한다.
public final class ConsentManager {

    public static let shared = ConsentManager()

    /// UMP 동의 흐름을 건너뛰는 지역(ISO 3166-1 alpha-2).
    /// 한국·일본은 GDPR/CCPA 대상이 아니므로 동의 수집 없이 바로 AdMob 을 초기화한다.
    private static let exemptedRegions: Set<String> = ["KR", "JP"]

    #if DEBUG
    /// DEBUG 빌드에서 UMP 폼 동작을 수동 테스트하기 위한 디버그 스위치.
    ///
    /// 사용법:
    /// 1. 아래 `debugGeographyEnabled` 를 `true` 로 변경
    /// 2. `debugGeography` 를 원하는 값으로 변경 (`.EEA`, `.regulatedUSState`, `.disabled`)
    /// 3. `debugTestDeviceIdentifiers` 에 실기기의 IDFA(또는 앱 첫 실행 시 콘솔에 출력되는 해시) 추가
    /// 4. 앱 삭제 후 재설치해야 이전 동의 상태가 초기화되어 폼이 다시 표시됨
    ///
    /// 배포 전 반드시 `debugGeographyEnabled = false` 로 되돌릴 것.
    static let debugGeographyEnabled: Bool = false
    static let debugGeography: UMPDebugGeography = .EEA
    static let debugTestDeviceIdentifiers: [String] = [
        // 예: "33BE2250-B28F-4B5C-8A96-AB7E5DC7E5E7"
    ]

    fileprivate static func makeDebugSettings() -> UMPDebugSettings? {
        guard debugGeographyEnabled else { return nil }
        let settings = UMPDebugSettings()
        settings.geography = debugGeography
        settings.testDeviceIdentifiers = debugTestDeviceIdentifiers
        return settings
    }
    #endif

    private var isMobileAdsStarted = false

    private init() {}

    /// 앱 시작 시 한 번 호출한다. (`MongleApp.init()` 에서 호출)
    /// - 지역이 KR/JP 이면 즉시 AdMob 초기화
    /// - 그 외 지역이면 최상위 ViewController 가 준비된 뒤 UMP 동의 폼을 노출하고,
    ///   동의 결과와 무관하게(거부 시 비개인화 광고) AdMob 을 초기화한다.
    public func startConsentFlowIfNeeded() {
        // DEBUG 빌드에서 디버그 모드가 활성화된 경우에는 KR/JP 판정도 UMP 가 수행하도록 하여
        // 테스트 지역을 강제로 시뮬레이션할 수 있게 한다.
        #if !DEBUG
        if Self.isExemptedRegion() {
            // KR/JP: UMP 는 건너뛰지만 ATT 는 여전히 요청한다 (개인화 광고 eCPM 확보).
            requestTrackingAuthorizationThenStartAds()
            return
        }
        #else
        if !Self.debugGeographyEnabled && Self.isExemptedRegion() {
            requestTrackingAuthorizationThenStartAds()
            return
        }
        #endif

        // UMP 요청 파라미터.
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false

        #if DEBUG
        if let debugSettings = Self.makeDebugSettings() {
            parameters.debugSettings = debugSettings
        }
        #endif

        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard let self else { return }
            if let error = error {
                // 네트워크 오류 등으로 상태를 알 수 없을 때는 ATT 와 AdMob 만 진행하여
                // 서비스 연속성을 확보한다. 개인화 여부는 AdMob 기본 정책을 따른다.
                #if DEBUG
                print("[UMP] requestConsentInfoUpdate failed: \(error.localizedDescription)")
                #endif
                self.requestTrackingAuthorizationThenStartAds()
                return
            }
            DispatchQueue.main.async {
                self.presentFormIfRequired()
            }
        }
    }

    /// 현재 사용자에게 "개인정보 옵션 다시 열기" 버튼을 노출해야 하는지 여부.
    /// UMP 가 GDPR/CCPA 대상으로 판정한 사용자에게만 `true` 를 반환한다.
    /// KR/JP 처럼 UMP 를 건너뛴 경우에는 `false`.
    public var isPrivacyOptionsRequired: Bool {
        UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
    }

    /// 앱 내 "Privacy options" 버튼 등에서 호출할 수 있는 재동의 트리거.
    /// UMP 가 폼 재표시를 허용하는 경우에만 실제로 폼이 열린다.
    public func presentPrivacyOptionsForm(from viewController: UIViewController,
                                          completion: ((Error?) -> Void)? = nil) {
        UMPConsentForm.presentPrivacyOptionsForm(from: viewController) { error in
            completion?(error)
        }
    }

    // MARK: - Private

    private func presentFormIfRequired() {
        guard let rootVC = Self.topViewController() else {
            // ViewController 가 아직 준비되지 않은 경우 짧은 지연 후 재시도.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.presentFormIfRequired()
            }
            return
        }

        UMPConsentForm.loadAndPresentIfRequired(from: rootVC) { [weak self] loadAndPresentError in
            guard let self else { return }
            if let error = loadAndPresentError {
                #if DEBUG
                print("[UMP] loadAndPresentIfRequired failed: \(error.localizedDescription)")
                #endif
            }
            // UMP 동의 수집 완료 → ATT 프롬프트 → AdMob 초기화 순으로 진행.
            // ATT 는 iOS 14.5+ 에서 IDFA 접근 전에 반드시 요청해야 하며, UMP 폼 이후
            // 노출하는 것이 Google UMP 가이드라인의 권장 순서이다.
            self.requestTrackingAuthorizationThenStartAds()
        }
    }

    /// ATT 프롬프트를 표시한 뒤 AdMob 을 초기화한다.
    /// - iOS 14.5 미만: ATT 개념이 없으므로 바로 AdMob 초기화
    /// - 이미 결정된 상태(`notDetermined` 이외): 재요청 없이 바로 AdMob 초기화
    /// - `notDetermined`: ATT 프롬프트 표시 후 결과와 무관하게 AdMob 초기화
    ///
    /// ATT 거부 시에도 AdMob 은 비개인화 광고로 정상 동작한다.
    private func requestTrackingAuthorizationThenStartAds() {
        if #available(iOS 14.5, *) {
            let current = ATTrackingManager.trackingAuthorizationStatus
            guard current == .notDetermined else {
                startMobileAdsIfNeeded()
                return
            }
            // 루트 VC 가 화면에 올라온 직후 프롬프트가 제대로 뜨도록 짧게 지연.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                ATTrackingManager.requestTrackingAuthorization { _ in
                    self?.startMobileAdsIfNeeded()
                }
            }
        } else {
            startMobileAdsIfNeeded()
        }
    }

    private func startMobileAdsIfNeeded() {
        guard !isMobileAdsStarted else { return }
        isMobileAdsStarted = true
        DispatchQueue.main.async {
            GADMobileAds.sharedInstance().start(completionHandler: nil)
        }
    }

    private static func isExemptedRegion() -> Bool {
        let region: String?
        if #available(iOS 16, *) {
            region = Locale.current.region?.identifier
        } else {
            region = Locale.current.regionCode
        }
        guard let code = region?.uppercased() else { return false }
        return exemptedRegions.contains(code)
    }

    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root: UIViewController? = base ?? {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first { $0 is UIWindowScene } as? UIWindowScene
            return windowScene?.windows.first { $0.isKeyWindow }?.rootViewController
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
#endif
