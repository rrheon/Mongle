# 작업 보고 (2026-03-16 Work.md 기반)

## 완료된 작업

---

### 1. 오늘의 질문 카드

**변경 파일:**
- `FamTreeServer/prisma/seed.ts`
- `FamTreeServer/src/app.ts`

**내용:**
- 질문 데이터 36개 → **100개**로 확장 (DAILY 30개, MEMORY 20개, VALUE 15개, DREAM 15개, GRATITUDE 10개, SPECIAL 10개)
- `seed.ts` 중복 실행 방지 로직 추가 (DB에 100개 이상 있으면 스킵)
- `seed.ts`에서 DailyQuestion 생성 코드 제거 (familyId 없어서 실패하던 버그 제거)
- **매일 정오 자동 배정 스케줄러 추가** (`src/app.ts`)
  - 5분마다 현재 시각 체크, 12시(noon)에 모든 가족에 DailyQuestion 없으면 자동 배정

> 시드 실행: `cd FamTreeServer && npm run db:seed`

---

### 2. 나의 몽글 캐릭터 클릭 동작

**변경 파일:**
- `MongleFeatures/.../Design/Components.swift`
- `MongleFeatures/.../Home/HomeView.swift`
- `MongleFeatures/.../MainTab/MainTabView.swift`

**변경 내용:**
- `MongleView`에 `isCurrentUser: Bool`, `onSelfTap: () -> Void` 파라미터 추가
  - 나의 캐릭터 탭 시 `onSelfTap()` 호출 → QuestionSheet 화면으로 이동
    - 답변한 경우: "답변 수정하기" 버튼 표시
    - 답변 안 한 경우: "답변하기" 버튼 표시
  - 나의 배지: "답변하기" / "답변완료" 텍스트, 브랜드/오렌지 색상으로 구별
- `MongleSceneView`에 `currentUserName: String?`, `onSelfTap: () -> Void` 파라미터 추가
- `HomeView`에 `currentUserName`, `onMyMonggleTap` 파라미터 추가
- `MainTabView`에서 `store.home.currentUser?.name`을 `currentUserName`으로 전달

---

### 3. MY 페이지 닉네임 (kakao 사용자 대신 입력한 닉네임 표시)

**변경 파일:**
- `MongleFeatures/.../Root/Ext/Root+Reducer.swift`

**원인:**
- `refreshHomeData`가 캐시된 `state.currentUser`를 사용해서, 그룹 가입 시 닉네임 업데이트 후에도 이전 Kakao 기본 이름("kakao 사용자")이 MY 페이지에 표시되던 문제

**수정:**
- `refreshHomeData`에서 매번 `authRepository.getCurrentUser()` 호출 → **항상 서버의 최신 이름** 반영

---

### 4. 하트 지급 팝업

**변경 파일:**
- `MongleFeatures/.../Root/Ext/Root+State.swift` — `showHeartGrantedPopup: Bool` 추가
- `MongleFeatures/.../Root/Ext/Root+Action.swift` — `dismissHeartPopup` 액션 추가
- `MongleFeatures/.../Root/Ext/Root+Reducer.swift` — 하루 첫 접속 감지 + 팝업 트리거
- `MongleFeatures/.../Root/RootView.swift` — 팝업 alert 추가

**동작:**
- 앱 데이터 로드 성공 시, UserDefaults의 마지막 팝업 날짜와 오늘 비교
- 오늘 처음 접속이면 "🎁 하트 +1 / 오늘 처음 접속하셨네요! 하트 1개를 드렸어요 ❤️" 팝업 표시
- 하루 1번만 표시 (UserDefaults key: `mongle.lastHeartPopupDate`)
