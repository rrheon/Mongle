# Search 화면 셀 너비 및 광고 배너 작업 보고서

**날짜**: 2026-03-24
**파일**: `MongleFeatures/Sources/MongleFeatures/Presentation/Search/SearchHistoryView.swift`

---

## 작업 내용

### 1. 셀 좌우 꽉 차게 변경
- `SearchResultCard`에 적용되던 `.padding(.horizontal, MongleSpacing.md)` 제거
- 카드가 화면 좌우 끝까지 꽉 차도록 수정

### 2. 광고 배너 삽입 로직 추가

**규칙**:
- 결과 셀이 11개 이하: 맨 끝에 광고 1개
- 결과 셀이 11개 초과: 11개마다 광고 1개 + 마지막 셀 이후 광고 1개

**구현 방식**:
- 날짜별 그룹 순서로 전체 결과에 전역 인덱스(`globalIndices: [String: Int]`) 부여
- `shouldShowAd(after:total:)` 헬퍼 함수로 광고 위치 판단
  ```swift
  (index + 1) % 11 == 0 || index + 1 == total
  ```
- `AdBannerSection()` 사용 (MyPage와 동일한 광고 UI)
- `#if os(iOS)` 컴파일 조건 적용

**광고 위치 예시**:
- 결과 8개 → 8번째 셀 이후 광고 1개
- 결과 11개 → 11번째 셀 이후 광고 1개
- 결과 25개 → 11번째, 22번째, 25번째 셀 이후 각각 광고

---

## 변경 파일
- `SearchHistoryView.swift` - `resultsList`, `shouldShowAd` 함수 추가
