# 작업 보고서 — 2026-03-26 (Work.md 5차)

## 작업 항목

### 1. 커스텀 팝업 — 아이콘 전체 제거

**변경 파일:** `MongleFeatures/.../Presentation/Common/MonglePopupView.swift`

**내용:**
- `icon: Icon` → `icon: Icon? = nil` (선택적 파라미터로 변경, 기존 호출부 컴파일 유지)
- `body`에서 `iconCircle` 참조 제거
- `iconCircle` computed property 삭제
- `EmptyView` convenience init도 동일하게 `icon: Icon? = nil`로 업데이트
- 결과: 모든 팝업에서 아이콘 원형 UI가 표시되지 않음

**참고:** 기존 호출부에서 `icon:` 인자를 전달하더라도 저장만 되고 렌더링되지 않으므로 컴파일 오류 없음

---

### 2. 계정 탈퇴 팝업 — 탈퇴하기 버튼 빨간색

**변경 파일:**
- `MongleFeatures/.../Presentation/Common/MonglePopupView.swift`
- `MongleFeatures/.../Presentation/Profile/AccountManagementView.swift`

**내용:**
- `MonglePopupView`에 `isDestructive: Bool = false` 파라미터 추가
- `isDestructive: true`일 때 primary 버튼을 `MongleColor.error`(빨간색) 배경으로 렌더링
- `AccountManagementView`의 `showDeleteConfirm` 팝업에 `isDestructive: true` 전달
- 같은 파일의 로그아웃/탈퇴 팝업에서 `icon:` 인자 제거 (아이콘 불필요)

---

### 3. SearchView — 검색결과 셀 전체 너비

**변경 파일:** `MongleFeatures/.../Presentation/Search/SearchHistoryView.swift`

**원인:** `SearchResultCard` 내부 `VStack`이 `.frame(maxWidth: .infinity)` 없이 콘텐츠 크기만큼만 늘어나 카드 배경이 내용 너비에만 적용됨

**내용:**
- `SearchResultCard.body`의 `VStack`에 `.frame(maxWidth: .infinity, alignment: .leading)` 추가 → 카드 배경이 전체 너비로 확장
- 카드 호출부에 `.padding(.horizontal, MongleSpacing.md)` 추가 → 다른 섹션 요소(날짜 헤더, 카운트 라벨)와 좌우 여백 정렬
