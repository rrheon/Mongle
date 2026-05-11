import Foundation

public protocol ConfigRepositoryProtocol: Sendable {
    /// 서버 /config 호출. 성공 시 AppConfig 반환, 실패 시 throw.
    /// 호출자가 결과를 캐시 (UserDefaults 등) 에 저장하는 책임을 진다.
    func fetch() async throws -> AppConfig
}
