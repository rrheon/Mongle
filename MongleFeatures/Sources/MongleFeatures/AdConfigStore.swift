import Foundation

/// 서버 /config 응답을 캐시하는 source-of-truth (MG-132).
///
/// MongleApp.init() 가 부팅 시 ConfigRepository.fetch() → [set] 으로 갱신한다.
/// AdBannerView 와 ConsentManager 는 [isAdEnabled] 를 읽어 광고 렌더링 / AdMob 초기화
/// 여부를 결정한다.
///
/// 기본값은 true (광고 표시) — 첫 부팅 / 네트워크 실패 시 운영 사고 없이 기존 동작 유지.
/// 운영자가 서버 환경변수 ADS_ENABLED=false 로 OFF 한 뒤 다음 부팅부터 반영된다.
public enum AdConfigStore {
    private static let key = "mongle.adConfig.isAdEnabled"

    public static var isAdEnabled: Bool {
        // object(forKey:) 가 nil 이면 미설정 → 기본값 true. bool(forKey:) 단독 사용 시
        // 미설정 / false 구분이 안 돼서 첫 부팅이 false 로 잘못 해석되는 회귀 방지.
        guard UserDefaults.standard.object(forKey: key) != nil else { return true }
        return UserDefaults.standard.bool(forKey: key)
    }

    public static func set(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: key)
    }
}
