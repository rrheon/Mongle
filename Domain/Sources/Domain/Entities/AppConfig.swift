import Foundation

/// 서버 /config 응답을 표현하는 도메인 엔티티 (MG-132).
public struct AppConfig: Sendable, Equatable {
    public let isAdEnabled: Bool

    public init(isAdEnabled: Bool) {
        self.isAdEnabled = isAdEnabled
    }
}
