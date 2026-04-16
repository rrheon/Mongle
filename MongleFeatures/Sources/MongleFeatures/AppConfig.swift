import Foundation

/// 앱 전역 설정 상수
public enum AppConfig {
    /// 서버 API base URL
    public static let apiBaseURL = "https://15i45fprse.execute-api.ap-northeast-2.amazonaws.com"

    /// 초대링크 랜딩 서버 — 배포 전이라 자체 도메인 없이 API Gateway 직결 사용.
    /// Universal Link는 불가(도메인 미보유)하지만, 랜딩 HTML이 monggle:// 커스텀 스킴으로 자동 전환.
    public static let webDomain = "https://15i45fprse.execute-api.ap-northeast-2.amazonaws.com"

    /// 초대 링크 생성 — AASA `/join/*` 및 서버 /join/:code 라우트와 일치
    public static func inviteLink(code: String) -> String {
        "\(webDomain)/join/\(code)"
    }

    /// 초대 공유 텍스트 생성
    public static func inviteShareText(code: String) -> String {
        L10n.tr("group_share_text", code, inviteLink(code: code))
    }
}
