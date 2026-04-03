# 작업

## 위치
- 디자인: /Users/yong/Desktop/FamTree/MongleUI
- iOS: /Users/yong/Desktop/FamTree
- Android: /Users/yong/Mongle-Android
- 서버: /Users/yong/Desktop/MongleServer

## 구글 ad정보

iOS
앱ID : ca-app-pub-4718464707406824~3555712259
- 배너: ca-app-pub-4718464707406824/5359748516
- 보상형: ca-app-pub-4718464707406824/2869316545

Android
앱ID: ca-app-pub-4718464707406824~8995741193
- 배너: ca-app-pub-4718464707406824/2974225929
- 보상형: ca-app-pub-4718464707406824/9365243021

---

## 버그 목록 및 상세 분석

### 버그 1: iOS 텍스트필드 플레이스홀더 색상 진하게

**현상:** 텍스트필드의 플레이스홀더 텍스트가 너무 연해서 잘 안 보임

**원인 분석:**
- `MongleFeatures/.../Presentation/Question/QuestionDetailView.swift` (line 182-189)
  - 네이티브 SwiftUI `TextField`를 사용 중이며, 플레이스홀더 색상이 시스템 기본(연한 회색)으로 표시됨
- `MongleFeatures/.../Presentation/Common/MongleTextField.swift` (line 156-162)
  - 커스텀 `MongleTextField`는 `Text` 오버레이로 플레이스홀더를 구현하여 `MongleColor.textHint` 적용 가능
  - 하지만 `QuestionDetailView`에서는 네이티브 `TextField`를 사용 중

**수정 방안:**
- `QuestionDetailView.swift`에서 네이티브 `TextField` 대신 `MongleTextField` 사용으로 변경
- 또는 `prompt` modifier + `.foregroundColor` 활용 (iOS 15+)
- 커스텀 플레이스홀더 `Text` 오버레이로 색상 제어:
```swift
ZStack(alignment: .topLeading) {
    if text.isEmpty {
        Text(L10n.tr("detail_answer_placeholder"))
            .foregroundColor(MongleColor.textSecondary) // 더 진한 색상
            .font(MongleFont.body2())
    }
    TextEditor(text: $text)
}
```

**영향도:** 낮음 | **수정 범위:** iOS 1파일

---

### 버그 2: Android 텍스트필드 플레이스홀더 색상 연하게

**현상:** 플레이스홀더가 너무 진해서 입력된 텍스트와 구분이 어려움

**원인 분석:**
- `Mongle-Android/.../ui/common/MongleTextField.kt` (line 38-42)
  - 플레이스홀더 색상이 `MaterialTheme.colorScheme.onSurfaceVariant`로 설정됨
  - 이 색상이 너무 진함
- `Color.kt`에 `MongleTextHint = Color(0xFF9E9E9E)` 정의되어 있으나 미사용

**수정 방안:**
```kotlin
// MongleTextField.kt line 40
// 기존: color = MaterialTheme.colorScheme.onSurfaceVariant
// 변경:
color = MongleTextHint.copy(alpha = 0.6f) // 또는 MongleTextHint 단독 사용
```

**영향도:** 낮음 | **수정 범위:** Android 1파일

---

### 버그 3: 그룹관리 화면 몽글 캐릭터 색상 싱크 불일치

**현상:** 그룹관리 화면에서 몽글 캐릭터의 색상이 실제 사용자 기분(moodId)과 다르게 표시됨

**원인 분석 (iOS):**
- `GroupManagementView.swift` (line 204, 269)
  - `monggleColor(for: index)` → 배열 인덱스 기반으로 색상 할당
  - 사용자의 실제 `moodId`를 무시하고 순서대로 Yellow, Green, Pink, Blue, Orange 배정
- `GroupManagementFeature.swift` (line 112)
  - `GroupMember` 생성 시 `colorHex: ""` (빈 문자열)로 설정 → `moodId` 정보 전달 안 됨

```swift
// 문제 코드 (GroupManagementView.swift line 319-325)
private func monggleColor(for index: Int) -> Color {
    let colors: [Color] = [
        MongleColor.monggleYellow, MongleColor.monggleGreen,
        MongleColor.mongglePink, MongleColor.monggleBlue, MongleColor.monggleOrange
    ]
    return colors[index % colors.count]
}
```

**원인 분석 (Android):**
- `SettingsScreen.kt` (line 913-993) MembersSection
  - `monggleColors[index % monggleColors.size]` → 동일하게 인덱스 기반 색상 할당
  - HomeScreen에서는 `moodColor(moodId, fallbackColor)` 로 올바르게 처리하지만 그룹관리에서는 누락

**수정 방안:**

iOS:
1. `GroupMember` 구조체에 `moodId` 필드 추가
2. `GroupManagementFeature.swift`에서 서버 응답의 `moodId` → `GroupMember.moodId`에 매핑
3. `monggleColor(for:)` 대신 `moodId` 기반 색상 함수 사용

Android:
1. MembersSection에서 `member.moodId` 기반 `moodColor()` 함수 적용
2. HomeScreen의 `moodColor(moodId, fallback)` 패턴 재사용

**영향도:** 중간 | **수정 범위:** iOS 2파일, Android 1파일

---

### 버그 4: 그룹나가기 시 위임 후 그룹선택 화면 이동 + 토스트

**현상:** 그룹에서 나간 뒤 그룹 선택화면으로 이동은 하지만 "그룹에서 나왔습니다" 토스트가 없음

**원인 분석 (iOS):**
- `GroupManagementFeature.swift` (line 140-160, 208-220)
  - 위임(transferCreator) → 탈퇴(leaveFamily) → `.delegate(.groupLeft)` 전송
- `MainTab+Reducer.swift` (line 209-210)
  - `.groupLeft` 수신 → `.navigateToGroupSelect(fromGroupLeft: true)` 전송
  - `fromGroupLeft: true` 파라미터가 전달되지만 **토스트 표시 로직 없음**

**원인 분석 (Android):**
- `SettingsViewModel.kt` (line 220-235)
  - transferCreator → leaveFamily → `SettingsEvent.LeftGroup` emit
- `SettingsScreen.kt` (line 137-140)
  - `LeftGroup` → `navController.popBackStack("my")` + `onGroupLeft()` 호출
  - 토스트 표시 없음 (string resource `toast_group_left`는 존재)

**수정 방안:**

iOS:
```swift
// Root 또는 GroupSelect에서 fromGroupLeft 파라미터 처리
case .navigateToGroupSelect(fromGroupLeft: true):
    state.showGroupLeftToast = true // 토스트 상태 추가
    // ... 기존 네비게이션 로직
```

Android:
```kotlin
// SettingsScreen.kt
SettingsEvent.LeftGroup -> {
    navController.popBackStack("my", inclusive = false)
    // 토스트 표시 추가
    Toast.makeText(context, context.getString(R.string.toast_group_left), Toast.LENGTH_SHORT).show()
    onGroupLeft()
}
```

**영향도:** 낮음 | **수정 범위:** iOS 1-2파일, Android 1파일

---

### 버그 5: iOS 답변 시 Android에서 몽글캐릭터가 미답변 상태로 표시

**현상:** iOS에서 답변을 완료했는데, Android의 홈화면에서 해당 가족의 몽글 캐릭터가 여전히 미답변으로 나옴. 마음 남기기 화면에서는 답변이 보임.

**원인 분석:**
- `MainTab+Reducer.swift` (line 400-441)
  - 답변 제출 시 `state.home.memberAnswerStatus[userId] = true`로 **로컬만 업데이트**
  - 서버에는 답변이 정상 저장되지만, 다른 기기에서는 홈화면 새로고침 시에만 반영
- `MainTabView.swift` (line 145-150)
  - 캐릭터 색상을 `memberAnswerStatus` 딕셔너리에서 조회
  - 이 딕셔너리는 **앱 시작 시 한 번만 로드**되고, 이후 로컬 답변 시에만 갱신

**핵심 문제:**
- 실시간 동기화 메커니즘 없음 (WebSocket/SSE 미사용)
- 푸시 알림 수신 시 `memberAnswerStatus` 갱신 로직 누락
- 홈화면 진입 시 강제 새로고침이 없거나 캐시된 데이터 사용

**수정 방안:**

1. **즉시 적용 가능:** 홈화면 진입(onAppear/onResume) 시 매번 서버에서 오늘의 질문 + 답변상태 새로고침
2. **Android 측 (HomeScreen.kt):** 
   - `LaunchedEffect` 또는 `onResume`에서 `viewModel.loadTodayQuestion()` 호출
   - 가족 답변 상태 포함하여 갱신
3. **iOS 측:**
   - 푸시 알림(답변 알림) 수신 핸들러에서 `memberAnswerStatus` 갱신
   - `MainTabView` onAppear에서 today question reload

**추가:** 마음 남기기 화면에서 가족의 답변 부분 제거 필요 (Android)
- `QuestionDetailScreen.kt`의 FamilyAnswersSection을 마음 남기기 화면에서 비노출 처리

**영향도:** 높음 | **수정 범위:** iOS 1-2파일, Android 1-2파일

---

### 버그 6: Android 질문 넘기기 오류

**현상:** Android에서 질문 넘기기가 동작하지 않음

**원인 분석:**

**서버 측 근본 원인 — 날짜 불일치:**
- `QuestionService.ts` (line 116-189) `skipTodayQuestion()`
  - `skippedDate`를 `dailyQuestion.date`로 저장하는데, `getTodayQuestion()`이 전날의 미완료 질문을 반환할 수 있음
  - `hasMySkipped` 판정 (line 514-518)에서 날짜 비교 실패:
    ```ts
    myMembership.skippedDate.getTime() === dailyQuestion.date.getTime()
    // skippedDate = 어제(4/2) vs 오늘 새 질문 = 오늘(4/3) → FALSE
    ```
  - 하트는 차감되지만 응답에서 `hasMySkipped = false` → 클라이언트에서 미반영 상태

**Android 클라이언트:**
- `HomeViewModel.kt` (line 259-279) `skipQuestion()`
  - `questionRepository.skipQuestion()` 호출 후 에러 핸들링이 일반적
  - 서버 에러 코드(400, 409 등) 별 분기처리 없음
- `ApiQuestionRepository.kt` (line 67-70) `safeCall` 래핑으로 상세 에러 정보 손실 가능
- `HomeScreen.kt` (line 432-467) 넘기기 확인 다이얼로그

**수정 방안:**

서버 수정 (핵심):
```ts
// QuestionService.ts skipTodayQuestion()
// 기존: const today = this.getToday(); → today로 skippedDate 저장
// 변경: 실제 활성 질문 조회 후 그 질문의 date를 skippedDate로 사용
async skipTodayQuestion(userId: string): Promise<SkipQuestionResponse> {
    // ... 사용자/가족 검증 ...
    const today = this.getToday();

    // ★ getTodayQuestion과 동일 로직으로 실제 활성 질문 조회
    let dailyQuestion = await prisma.dailyQuestion.findUnique({
        where: { familyId_date: { familyId: user.familyId, date: today } },
        include: { question: true },
    });

    if (!dailyQuestion) {
        const twoDaysAgo = new Date(today);
        twoDaysAgo.setUTCDate(twoDaysAgo.getUTCDate() - 2);
        const recentDQ = await prisma.dailyQuestion.findFirst({
            where: { familyId: user.familyId, date: { gte: twoDaysAgo, lt: today } },
            include: { question: true },
            orderBy: { date: 'desc' },
        });
        if (recentDQ) {
            const allCompleted = await this.isQuestionCompleted(
                user.familyId, recentDQ.questionId, recentDQ.date
            );
            if (!allCompleted) dailyQuestion = recentDQ;
        }
    }

    if (!dailyQuestion) throw Errors.notFound('오늘의 질문');

    // ★ 실제 질문의 날짜를 skippedDate로 사용
    const questionDate = dailyQuestion.date;

    // ... 이하 skippedDate = questionDate로 처리 ...
}
```

Android 에러 핸들링 개선:
```kotlin
// HomeViewModel.kt skipQuestion()
.onFailure { e ->
    val message = when {
        e.message?.contains("이미 답변") == true ->
            context.getString(R.string.error_already_answered_skip)
        e.message?.contains("하트가 부족") == true ->
            context.getString(R.string.home_hearts_insufficient_title)
        else -> e.message ?: context.getString(R.string.error_skip_failed)
    }
    _uiState.update { it.copy(isLoading = false, errorMessage = message) }
}
```

**영향도:** 높음 (하트 손실) | **수정 범위:** 서버 1파일, Android 1파일

---

### 버그 7: "이미 답변한 질문은 넘길 수 없습니다" 팝업 다국어 처리 누락

**현상:** 해당 에러 메시지가 다국어 처리 안 되어 한국어만 표시됨

**원인 분석:**
- Android strings.xml에 해당 문자열 리소스 없음
- 서버에서 반환하는 에러 메시지("이미 답변한 질문은 패스할 수 없습니다")를 그대로 표시 중

**수정 방안:**

각 strings.xml에 추가:
```xml
<!-- values-ko/strings.xml -->
<string name="error_already_answered_skip">이미 답변한 질문은 넘길 수 없어요</string>

<!-- values/strings.xml (English) -->
<string name="error_already_answered_skip">You cannot skip a question you\'ve already answered</string>

<!-- values-ja/strings.xml (Japanese) -->
<string name="error_already_answered_skip">既に回答した質問はスキップできません</string>
```

클라이언트에서 서버 에러 코드(409 Conflict)를 감지하여 로컬라이즈된 문자열 표시.

**영향도:** 낮음 | **수정 범위:** Android 3파일 (strings.xml) + 1파일 (ViewModel)

---

### 버그 8: Android My화면 — 기분 히스토리, 몽글카드 편집 제거

**현상:** My 화면에 기분 히스토리, 몽글카드 편집 메뉴가 있으나 제거 필요 (준비중 상태)

**원인 분석:**
- `SettingsScreen.kt` (line 326-341)
  - 기분 히스토리: `SettingsRowData(icon=Timeline, title=settings_mood_history, ...)`
  - 몽글카드 편집: `SettingsRowData(icon=Edit, title=settings_mongle_card, ...)`
- `SettingsScreen.kt` (line 1157-1185) MoodHistoryScreen → "준비 중" 플레이스홀더
- `SettingsScreen.kt` (line 1190-1260) MongleCardEditScreen → 비활성화된 편집 인터페이스
- NavHost 라우팅 (line 245-254) → "mood_history", "mongle_card_edit" 경로

**수정 방안:**
삭제 대상:
1. SettingsRowData 2개 (line 326-341) — 메뉴 항목
2. `onMoodHistoryTapped`, `onMongleCardEditTapped` 콜백 파라미터
3. NavHost 라우팅 2개 (line 245-254)
4. MoodHistoryScreen 컴포저블 (line 1157-1185)
5. MongleCardEditScreen 컴포저블 (line 1190-1260)
6. MyScreen 함수 시그니처에서 해당 람다 제거

**영향도:** 낮음 | **수정 범위:** Android 1파일 (SettingsScreen.kt)

---

### 버그 9: iOS 히스토리 화면에서 다른 사용자 답변을 볼 수 없음

**현상:** 본인이 답변을 완료했음에도 히스토리에서 다른 가족의 답변이 보이지 않음

**원인 분석:**
- `HistoryFeature.swift` (line 216-232)
  - `hq.answers` 배열을 `MemberAnswer`로 매핑하여 `HistoryItem.memberAnswers`에 저장
  - 클라이언트 필터링 문제는 아님 — 모든 답변을 그대로 표시
- `HistoryFeature.swift` (line 207)
  - `questionRepository.getHistory(page: 1, limit: 60)` 호출
  - **서버 응답에 가족 답변이 포함되지 않을 가능성**

**서버 측 확인:**
- `QuestionService.ts` `getQuestionHistory()` (line 293-309)
  - 히스토리 응답에 가족 답변 포함 여부 확인 필요
  - skip 상태 체크에서도 동일한 날짜 비교 문제 존재 가능

**수정 방안:**
1. 서버 `/questions` (히스토리) API 응답에 `answers` 배열이 포함되는지 확인
2. 서버에서 본인 답변 여부와 관계없이 가족 답변을 반환하도록 수정
3. 클라이언트에서 답변 표시 조건 확인 (본인 미답변 시 가족 답변 숨김 처리가 있는지)

**영향도:** 중간 | **수정 범위:** 서버 1파일 확인 필요, iOS 1파일

---

### 버그 10: Android 답변 수정 시 몽글캐릭터 색상 싱크 불일치

**현상:** 답변 수정 후 홈화면의 몽글캐릭터 색상이 변경된 기분에 맞게 갱신되지 않음

**원인 분석 (iOS):**
- `HomeScreen/QuestionDetail`의 default 색상 불일치 → **모두 Pink으로 통일**
- `HistoryView`는 `moodId→colorIndex` 변환으로 정상 동작 확인

**원인 분석 (Android):**
- `QuestionDetailScreen.kt` (line 462-510) `FamilyAnswerItem`
  - `familyAnswer.answer.moodId`로 색상 결정 → 매핑 자체는 정상
- `QuestionDetailViewModel.kt` (line 188-223) `doSubmitAnswer()`
  - 답변 수정 시 `myAnswer` 상태는 업데이트하지만, 홈화면의 `memberAnswerStatus`나 `moodId`는 별도 갱신 필요
- **HomeScreen.kt** (line 164-170)
  - `QuestionDetailScreen`이 `role.ordinal` 인덱스 기반 → **`answer.moodId` 기반으로 수정 필요**

**답변/수정/스킵 로직 추가 확인:**
- Android: 답변 제출 후 가족답변 새로고침 누락 → **`onAnswerSubmitted()`에 `loadFamilyAnswers()` 추가**
- 서버: 답변 수정 시 하트 -1 차감 → ✅ `AnswerService.ts` (line 264-274) 정상 구현됨
- 서버: createAnswer에 가족 소속 질문 검증 → ✅ `AnswerService.ts` (line 40-48) 정상 구현됨

**수정 방안:**
1. Android HomeScreen: 색상 결정을 `role.ordinal` → `moodId` 기반으로 변경
2. 답변 수정 완료 → 홈화면 복귀 시 today question 재로드
3. `onAnswerSubmitted()` 콜백에서 `loadFamilyAnswers()` 호출 추가

**영향도:** 중간 | **수정 범위:** Android 2파일

---

### 버그 11: 하트 부족 시 광고보기 무반응

**원인 A — Android: 광고 버튼 다국어 미처리**
- `HomeScreen.kt` (line 444-465)
  - 광고 보기 버튼 자체는 구현되어 있으나 `"광고 보고 넘기기"` 하드코딩 → 다국어 리소스 미사용
  
수정:
```kotlin
// line 455
// 기존: primaryLabel = if (adManager != null) "광고 보고 넘기기" else ...
// 변경:
primaryLabel = if (adManager != null) stringResource(R.string.home_watch_ad_skip) else stringResource(R.string.common_confirm)
```

각 strings.xml에 추가:
```xml
<!-- ko --> <string name="home_watch_ad_skip">광고 보고 넘기기</string>
<!-- en --> <string name="home_watch_ad_skip">Watch ad and skip</string>
<!-- ja --> <string name="home_watch_ad_skip">広告を見てスキップ</string>
```

**원인 B — iOS: 광고 실패 시 에러 처리**
- `MainTab+Reducer.swift` (line 265-284)
  - 광고 실패 시 `.skipQuestionResponse(.failure(...))` 전송 → 에러 토스트 표시됨
  - 다만 `state.modal = nil`로 팝업이 먼저 닫혀서 사용자가 재시도 경로 없음
  - `.skipQuestionResponse` 액션을 재사용하는 것은 의미적으로 부적절

수정:
```swift
guard earned else {
    // 전용 에러 액션 사용 + 재시도 가능한 팝업 유지
    await send(.adLoadFailed("광고를 불러올 수 없습니다. 다시 시도해주세요."))
    return
}
```

**영향도:** 중간 | **수정 범위:** Android 4파일 (strings.xml × 3 + HomeScreen), iOS 1파일

---

## 수정 우선순위

| 순서 | 버그 | 영향도 | 플랫폼 | 핵심 원인 |
|------|------|--------|--------|-----------|
| 1 | 버그 6: 질문 넘기기 (서버 날짜 불일치) | 높음 — 하트 손실 | 서버 | skippedDate와 dailyQuestion.date 불일치 |
| 2 | 버그 5: 답변 시 상대방 몽글 미반영 | 높음 | iOS+Android | 실시간 동기화 없음, 새로고침 누락 |
| 3 | 버그 10: 답변수정 시 색상 싱크 | 중간 | Android | moodId 미반영, 새로고침 누락 |
| 4 | 버그 3: 그룹관리 몽글 색상 | 중간 | iOS+Android | 인덱스 기반 색상 → moodId 기반 필요 |
| 5 | 버그 9: 히스토리 답변 안 보임 | 중간 | iOS(+서버) | 서버 응답 확인 필요 |
| 6 | 버그 11: 광고 무반응 | 중간 | iOS+Android | 다국어 누락, 에러 UX 미흡 |
| 7 | 버그 8: My화면 메뉴 제거 | 낮음 | Android | 미완성 기능 정리 |
| 8 | 버그 7: 넘기기 팝업 다국어 | 낮음 | Android | strings.xml 추가 |
| 9 | 버그 4: 그룹나가기 토스트 | 낮음 | iOS+Android | 토스트 표시 로직 추가 |
| 10 | 버그 1: iOS 플레이스홀더 진하게 | 낮음 | iOS | 색상 변경 |
| 11 | 버그 2: Android 플레이스홀더 연하게 | 낮음 | Android | 색상 변경 |
