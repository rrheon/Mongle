import Foundation

/// 서버 ISO 8601 날짜 문자열 파싱 (밀리초 포함/미포함 모두 지원)
/// 서버(Prisma)는 "2026-04-13T12:00:00.000Z" (밀리초 포함) 형식을 반환함.
/// ISO8601DateFormatter 기본 설정은 밀리초를 지원하지 않아 파싱 실패 → Date()로 폴백되는 버그 방지.
func parseISO8601(_ string: String) -> Date {
    let formatter = ISO8601DateFormatter()
    // 밀리초 포함 형식 먼저 시도
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: string) { return date }
    // 밀리초 미포함 형식 폴백
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: string) ?? Date()
}
