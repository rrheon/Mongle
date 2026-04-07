import Foundation

/// 앱 전역 설정 상수
public enum AppConfig {
    /// 서버 API base URL
    public static let apiBaseURL = "https://1cq1kfgvf1.execute-api.ap-northeast-2.amazonaws.com"

    /// Universal Link 도메인 (AASA 파일은 https://monggle.app/.well-known/apple-app-site-association)
    public static let webDomain = "https://monggle.app"

    /// 초대 링크 생성 — AASA `/join/*` 및 서버 /join/:code 라우트와 일치
    public static func inviteLink(code: String) -> String {
        "\(webDomain)/join/\(code)"
    }

    /// 초대 공유 텍스트 생성
    public static func inviteShareText(code: String) -> String {
        L10n.tr("group_share_text", code, inviteLink(code: code))
    }
}
