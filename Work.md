# 작업

다음의 로직 확인하기
- ~~그룹선택화면, 홈화면, 기록화면, my화면, 답변상세화면에서 몽글캐릭터(해당 날짜에 사용자가 선택한 색)이 싱크가 맞게 나오는지~~ ✅
- ~~질문에 대해 답변하기, 수정하기, 스킵하기 등의 로직이 제대로 돌아가는지~~ ✅
  - ~~해당 작업 후 서버와의 통신이 제대로 이뤄지는지, 각 그룹별로 개별적으로 적용이 되는지~~ ✅

### 검증 결과 및 수정사항

**iOS 색상 싱크:**
- HomeScreen/QuestionDetail의 default 색상이 불일치 → **모두 Pink으로 통일**
- HistoryView는 moodId→colorIndex 변환으로 정상 동작 확인

**Android 색상 싱크:**
- QuestionDetailScreen이 role.ordinal 인덱스 기반 → **answer.moodId 기반으로 수정**

**답변/수정/스킵 로직:**
- iOS: 답변·수정·스킵 후 서버통신, 히스토리 새로고침, 그룹별 상태 분리 모두 정상
- Android: 답변 제출 후 가족답변 새로고침 누락 → **onAnswerSubmitted()에 loadFamilyAnswers() 추가**
- 서버: 답변 수정 시 하트 차감 누락 → **updateAnswer에 하트 -1 트랜잭션 추가**
- 서버: createAnswer에 가족 소속 질문 검증 누락 → **dailyQuestion 확인 추가 (보안)**
  
## 위치
디자인: /Users/yong/Desktop/FamTree/MongleUI
iOS: /Users/yong/Desktop/FamTree
Andriod: /Users/yong/Mongle-Android 
서버: /Users/yong/Desktop/MongleServer
---
## 버그 분석 및 수정 방안

### 버그 1·2: 질문넘김 시 UI만 적용, 서버 미반영 / 그룹 전환 후 미답변 상태 (하트 차감됨)

**근본 원인: 서버 날짜 불일치**

`skipTodayQuestion()` (QuestionService.ts:121)에서 `skippedDate`를 항상 **오늘 날짜**(`this.getToday()`)로 저장함.
하지만 `getTodayQuestion()` (QuestionService.ts:54-75)은 **전날의 미완료 질문**을 반환할 수 있음.

`hasMySkipped` 판정 (QuestionService.ts:467-470):
```ts
membership.skippedDate.getTime() === dailyQuestion.date.getTime()
// skippedDate = 오늘(4/3) vs dailyQuestion.date = 어제(4/2) → FALSE!
```

→ 하트는 차감되지만 서버 응답의 `hasMySkipped = false` → 그룹 전환 후 새로고침 시 "미답변" 상태로 표시됨.

**수정:** `skipTodayQuestion()`에서 실제 표시 중인 질문의 날짜를 `skippedDate`로 저장

```
파일: MongleServer/src/services/QuestionService.ts
수정 위치: skipTodayQuestion() (line 116-168)
```

```ts
// 기존: const today = this.getToday();
// 변경: 실제 활성 질문 조회 후 그 날짜 사용
async skipTodayQuestion(userId: string): Promise<SkipQuestionResponse> {
    const user = await prisma.user.findUnique({ where: { userId } });
    if (!user) throw Errors.notFound('사용자');
    if (!user.familyId) throw Errors.badRequest('가족에 속해 있지 않습니다.');

    const today = this.getToday();

    // ★ 실제 표시 중인 질문 조회 (getTodayQuestion과 동일 로직)
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

    // ★ skippedDate는 실제 질문의 날짜 사용
    const questionDate = dailyQuestion.date;

    const membership = await prisma.familyMembership.findUnique({
        where: { userId_familyId: { userId: user.id, familyId: user.familyId } },
    });
    if (!membership) throw Errors.notFound('멤버십');

    const alreadySkipped =
        membership.skippedDate !== null &&
        membership.skippedDate.getTime() === questionDate.getTime();
    if (alreadySkipped) {
        throw Errors.conflict('오늘 이미 질문을 패스했습니다.');
    }

    const currentHearts = membership.hearts ?? 0;
    if (currentHearts < 3) {
        throw Errors.badRequest('하트가 부족합니다. 하트 3개가 필요합니다.');
    }

    // 이미 답변한 경우 패스 불가
    const myAnswer = await prisma.answer.findFirst({
        where: { questionId: dailyQuestion.question.id, userId: user.id },
    });
    if (myAnswer) throw Errors.conflict('이미 답변한 질문은 패스할 수 없습니다.');

    // ★ skippedDate = 질문 날짜, 하트 -3
    const [updatedMembership] = await prisma.$transaction([
        prisma.familyMembership.update({
            where: { userId_familyId: { userId: user.id, familyId: user.familyId } },
            data: { skippedDate: questionDate, hearts: { decrement: 3 } },
        }),
    ]);

    return {
        message: '질문을 패스했습니다.',
        heartsRemaining: updatedMembership.hearts,
    };
}
```

---

### 버그 3: 하트가 없을 때 광고보기를 누르면 아무것도 일어나지 않음

**원인 A — Android: 광고보기 버튼 자체가 없음**

`HomeScreen.kt:444-451`에서 하트 부족 시 "하트가 부족합니다" 안내 팝업만 표시하고 "광고 보기" 버튼이 없음.
(Nudge/답변수정에는 광고 기능 있지만, 질문 넘기기에는 누락됨)

```
파일: Mongle-Android/.../ui/home/HomeScreen.kt (line 444-451)
```

수정: iOS의 HeartCostPopupView처럼 "광고 보고 넘기기" 버튼 추가 필요
```kotlin
} else {
    MonglePopup(
        title = stringResource(R.string.home_hearts_insufficient_title),
        description = stringResource(R.string.home_hearts_insufficient_skip, currentHearts),
        primaryLabel = stringResource(R.string.home_watch_ad_skip), // "광고 보고 넘기기"
        onPrimary = {
            showSkipConfirmDialog = false
            // adManager로 광고 재생 → 하트 지급 → 넘기기 실행
            viewModel.watchAdForSkip(adManager)
        },
        secondaryLabel = stringResource(R.string.common_cancel),
        onSecondary = { showSkipConfirmDialog = false }
    )
}
```

HomeViewModel에 `watchAdForSkip()` 추가 필요:
```kotlin
fun watchAdForSkip(adManager: AdManager) {
    viewModelScope.launch {
        adManager.showRewardedAd(
            onRewarded = {
                viewModelScope.launch {
                    try {
                        userRepository.grantAdHearts(3)
                        skipQuestion()
                    } catch (e: Exception) {
                        _uiState.update { it.copy(errorMessage = "광고 보상 지급 실패") }
                    }
                }
            },
            onFailed = {
                _uiState.update { it.copy(errorMessage = "광고를 불러올 수 없습니다.") }
            }
        )
    }
}
```

**원인 B — iOS: 광고 실패 시 무반응**

`MainTab+Reducer.swift:270-271`에서 광고 시청 실패 시 `guard earned else { return }` 으로 조용히 종료됨.
팝업은 이미 닫힌 상태(`state.modal = nil`, line 267)이므로 사용자에게 아무 피드백 없음.

```
파일: MongleFeatures/.../MainTab/Ext/MainTab+Reducer.swift (line 265-279)
```

수정: 광고 실패 시 에러 토스트 표시
```swift
case .modal(.presented(.heartCostPopup(.delegate(.watchAdRequested(let costType))))):
    state.modal = nil
    let cost = costType.cost
    return .run { [costType, cost] send in
        let earned = await adClient.showRewardedAd()
        guard earned else {
            // ★ 실패 시 에러 전달
            await send(.adLoadFailed)
            return
        }
        // ... 기존 로직
    }
```

---

### 수정 우선순위

| 순서 | 버그 | 영향도 | 수정 범위 |
|------|------|--------|-----------|
| 1 | 서버 날짜 불일치 (버그1·2) | 높음 — 하트 손실 | 서버 1파일 |
| 2 | Android 광고 버튼 누락 (버그3-A) | 중간 | Android 2파일 |
| 3 | iOS 광고 실패 무반응 (버그3-B) | 낮음 | iOS 1파일 |

---

## 구글 ad정보

iOS
앱ID : ca-app-pub-4718464707406824~3555712259
- 배너
ca-app-pub-4718464707406824/5359748516
- 보상형
ca-app-pub-4718464707406824/2869316545

Andriod
앱ID: ca-app-pub-4718464707406824~8995741193
- 배너
 ca-app-pub-4718464707406824/2974225929

- 보상형
 ca-app-pub-4718464707406824/9365243021
