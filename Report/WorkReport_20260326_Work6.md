# 작업 보고서 — 2026-03-26 (Work.md 6차)

## 작업 항목

### 1. 답변 수정하기 팝업

**변경 파일:**
- `MongleFeatures/.../Presentation/Common/HeartCostPopupFeature.swift`
- `MongleFeatures/.../Presentation/Question/QuestionDetailView.swift`
- `MongleFeatures/.../Presentation/Common/MonglePopupView.swift`

**내용:**

| 항목 | 변경 내용 |
|------|-----------|
| 내용 한 줄로 | `"답변을 수정하면\n하트 1개가 소모됩니다."` → `"답변을 수정하면 하트 1개가 소모됩니다."` |
| 뒤 배경 투명 | `.fullScreenCover(item:)` → `.overlay { if let popupStore = store.scope(...) { ... } }` 로 변경. 기존 fullScreenCover는 불투명 시트로 표시되어 뒤 화면이 가려졌으나, overlay 방식은 MonglePopupView의 반투명 딤 배경만 표시됨 |
| 화면 액션 제거 | `MonglePopupView`의 배경 `Color.black.opacity(0.45)`에 붙어있던 `.onTapGesture { onSecondary?() }` 제거. 배경 탭으로 팝업이 닫히는 동작 전체 제거 |

---

### 2. 그룹 나가기 팝업 — 나가기 버튼 빨간색

**변경 파일:**
- `MongleFeatures/.../Presentation/Group/GroupSelectView+Select.swift`
- `MongleFeatures/.../Presentation/Support/GroupManagementView.swift`

**내용:**
- 두 화면의 "그룹 나가기" 팝업 모두에 `isDestructive: true` 추가
- "나가기" 버튼이 `MongleColor.error`(빨간색) 배경으로 표시됨
- 불필요한 `icon:` 인자도 함께 제거

---

### 3. 답변 재촉하기 화면 (PeerNudgeView)

**변경 파일:**
- `MongleFeatures/.../Presentation/Peer/PeerNudgeFeature.swift`
- `MongleFeatures/.../Presentation/Peer/PeerNudgeView.swift`
- `MongleFeatures/.../Presentation/MainTab/Ext/MainTab+Reducer.swift`

**내용:**

| 항목 | 변경 내용 |
|------|-----------|
| 재촉하기 버튼 하단 고정 | `nudgeCard` 내부에 있던 `Spacer()`와 `nudgeButton`을 제거하고, ScrollView 아래 별도 영역에 `nudgeButton` 배치. 화면 하단에 항상 고정 표시 |
| 몽글 캐릭터 색상 | `PeerNudgeFeature.State`에 `memberMoodId: String?` 프로퍼티 추가. `MainTab+Reducer`에서 `PeerNudgeFeature.State` 생성 시 `targetUser.moodId` 전달. `PeerNudgeView.emptyState`에서 moodId를 색상으로 변환하는 `monggleColor(for:)` 헬퍼 추가 후 적용 |
