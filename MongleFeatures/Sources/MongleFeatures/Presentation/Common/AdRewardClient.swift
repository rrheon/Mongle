//
//  AdRewardClient.swift
//  MongleFeatures
//
//  광고 보상 하트 지급 호출의 retry 정책을 한 곳에 두기 위한 유틸.
//  PeerNudgeFeature, QuestionDetailFeature 등 여러 진입점에서 공통 사용.
//

import Foundation
import Domain

enum AdRewardClient {
    /// `userRepository.grantAdHearts(amount:)` 를 최대 `maxRetries` 회 재시도.
    ///
    /// - Why: 광고는 이미 시청 완료된 시점에 호출되므로, 일시적 네트워크 오류로
    ///   보상 지급이 실패하면 사용자는 광고 시간만 손해보고 하트를 받지 못한다.
    ///   exponential backoff(500ms → 1s → 2s) 로 transient 오류를 흡수한다.
    /// - Note: 모든 시도가 실패하면 마지막 에러를 throw — 호출부가 명시적 안내 책임.
    static func grantAdHearts(
        userRepository: any UserRepositoryInterface,
        amount: Int,
        maxRetries: Int = 3
    ) async throws -> Int {
        var lastError: Error?
        for attempt in 0..<maxRetries {
            do {
                return try await userRepository.grantAdHearts(amount: amount)
            } catch {
                lastError = error
                if attempt < maxRetries - 1 {
                    let backoffNanos = UInt64(500_000_000) << attempt // 0.5s, 1s, 2s
                    try? await Task.sleep(nanoseconds: backoffNanos)
                }
            }
        }
        throw lastError ?? AppError.unknown("ad reward grant failed")
    }
}
