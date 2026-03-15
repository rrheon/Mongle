import Foundation

public protocol NudgeRepositoryInterface: Sendable {
    /// 재촉하기 — 하트 1개 차감 후 상대에게 알림 전송
    /// - Returns: 차감 후 남은 하트 잔액
    func sendNudge(targetUserId: String) async throws -> Int
}
