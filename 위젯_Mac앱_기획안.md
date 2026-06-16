# 몽글 위젯 & macOS 앱 기획안

> 원본 프롬프트: `Work.md`
> 작성일: 2026-05-13
> 기반 코드: `MongleFeatures/Sources/MongleFeatures/Design/Components.swift` (`MongleSceneView` L1323~1556)

---

## 0. 컨셉 한 줄

> **"위젯은 정보가 아니다. 가족 캐릭터가 거기서 뛰어다니는 것 자체가 위젯이다."**

기존 위젯이 보통 "오늘의 답변 3/5" 같은 정보 카드인 것과 정반대 방향. 텍스트·숫자·아이콘 전부 빼고, **메인 앱 HomeView의 통통 튀는 캐릭터를 작은 창으로 옮긴 것**이 위젯의 전부다. 가족의 존재감 = 캐릭터의 움직임.

## 0.1 확정 결정 사항

| 결정 | 값 |
|---|---|
| **macOS 최소 타겟** | macOS 14 Sonoma |
| **위젯에 보일 캐릭터 수** | 본인 + 가족 (최대 5명) |
| **CloudKit 동기화** | 사용 안 함, App Group만 |
| **위젯 콘텐츠** | **캐릭터만. 텍스트 0, 아이콘 0, 정보 0** |
| **위젯 인터랙션** | 탭 → 메인 앱 열기. 그 외 일체 없음 (하트 버튼/Live Activity/Control 위젯 제거) |
| **좌표 일치 강도** | 느슨 — 위젯 자체 레이아웃, 메인 앱 좌표 동기화 안 함 |

---

## 1. 기능 명세 (대폭 축소)

### 1.1 iOS 위젯 — 3종 사이즈, 같은 컨셉

| ID | 사이즈 | 동작 | iOS |
|---|---|---|---|
| W-S | systemSmall | 캐릭터 1마리(본인)가 통통 뛰어다님 | 17+ |
| W-M | systemMedium | 캐릭터 최대 5마리가 뛰어다님 | 17+ |
| W-L | systemLarge | 캐릭터 최대 5마리가 더 넓은 공간에서 뛰어다님 | 17+ |

위젯 어디에도 텍스트 없음. 답변 여부 시각화는 캐릭터 자체의 시각 변화로 (예: 답변한 캐릭터는 outline 글로우, 안 한 캐릭터는 흐림 — 선택적, MVP 후 결정).

**탭 동작**: 어떤 위젯이든 탭 → 메인 앱 HomeView로 열림. 단일 동작.

### 1.2 macOS 앱

| ID | 기능 | 설명 |
|---|---|---|
| M-MAIN | **메인 윈도우** | iOS HomeView 와이드 버전. 시뮬레이션 영역이 화면 대부분. 텍스트 UI는 상단 미니 헤더 정도 |
| M-DESK | **데스크탑 위젯** | iOS W-M / W-L 과 동일 위젯이 macOS 데스크탑에 배치. 캐릭터만 |
| M-HOVER | **마우스 오버 인터랙션** | 메인 앱 캐릭터 위 hover → scale 1.0→1.15 + 1회 점프. **Mac 차별 포인트** |
| M-BAR | **MenuBarExtra (선택)** | 메뉴바 아이콘이 캐릭터(본인). 클릭 시 작은 팝오버에 가족 캐릭터들이 뛰어다님 |

MenuBarExtra는 macOS Phase에서 시간 남으면. 핵심은 데스크탑 위젯과 hover.

### 1.3 이벤트 반응 — MVP에서 제외

§1 이전 안에 있던 ✦ 파티클/ring/🔥 이펙트는 **컨셉 단순화로 전부 후속 버전 이관**. 가족이 마음 남겼다고 위젯이 빠르게 변하면 "정보 위젯"으로 회귀. 그건 기존 알림으로 충분.

---

## 2. 디자인 가이드

### 2.1 캐릭터 픽셀 디자인

| 항목 | 값 |
|---|---|
| 그리드 | 16 × 16 픽셀 (논리) |
| 표시 크기 | systemSmall: 40pt / systemMedium: 36pt / systemLarge: 36pt |
| Outline | 1픽셀, `mongleNeon.primary` |
| 글로우 | `.shadow(color: primary.opacity(0.5), radius: 6)` — 정지 시에도 살아있음 |
| 색 변형 | 가족 색마다 PNG (5종) 또는 단일 PNG + `.colorMultiply` — MVP는 PNG 5종이 단순 |

자산 파이프라인: MongleUI(.pen) → PNG 1x/2x/3x → `MongleData/Assets.xcassets` 내부의 별도 **Widget Asset Catalog** (메인 앱 자산과 분리해 위젯 다운로드 사이즈 최소화).

### 2.2 위젯 배경

- **`.containerBackground(for: .widget)`** 모디파이어로 시스템 배경 사용
- 옵션: 신스웨이브 그리드 라인 (`rgba(255,255,255,0.08)`) 을 배경에 깔지 결정 필요 — MVP는 빼고 캐릭터만 두는 게 깔끔

### 2.3 캐릭터 움직임 — 위젯에서 "뛰어다님"을 어떻게 구현할까

WidgetKit은 60fps가 안 되지만, iOS 17+ `PhaseAnimator` 와 timeline entry 갱신을 조합하면 **"띄엄띄엄 뛰어다님"** 이 가능하다.

**전략 A: PhaseAnimator로 hop만** (보장됨)
```swift
content.phaseAnimator([0, -10, 0, -6, 0]) { content, dy in
    content.offset(y: dy)
} animation: { _ in .easeInOut(duration: 0.4) }
```
위젯이 화면에 보이는 동안 시스템이 허용하면 자동 재생. **확실히 동작**. 위치는 안 변함.

**전략 B: Timeline Entry로 위치 이동** (5분마다)
- TimelineProvider가 5분마다 새 entry 발행, 각 entry에 캐릭터 좌표를 다르게 (메인 앱의 `step()` 로직을 5분치 미리 시뮬레이션)
- 위젯 사이 transition은 iOS 17+ 의 `.contentTransition(.numericText())` 같은 식으로 부드럽게
- "5분 후 다른 위치"라 진짜 뛰어다니는 느낌은 약함

**채택안: A + B 결합**
- 화면 표시 중에는 PhaseAnimator로 통통(=hop)
- 5분마다 timeline entry가 위치를 살짝 옮김 → 다음 번에 보면 "어, 옮겨가있네" 라는 인지
- Timeline transition을 spring으로 주면 시스템이 위치 변화를 부드럽게 보간

> **솔직한 한계**: 위젯에서는 메인 앱 HomeView 같은 "지금 이 순간 뛰어다님"은 불가능. "매번 볼 때마다 다른 곳에 있는 + 통통 뛰는" 캐릭터 정도가 한계. 이걸 받아들이고 가면 됨.

### 2.4 레이아웃 — 사이즈별

```
systemSmall (158×158)               systemMedium (329×158)              systemLarge (329×345)
┌──────────────┐                    ┌────────────────────────┐         ┌────────────────────────┐
│              │                    │                        │         │                        │
│              │                    │   ◉    ◉               │         │                        │
│      ◉       │                    │      ◉      ◉          │         │     ◉      ◉           │
│              │                    │  ◉                     │         │       ◉                │
│              │                    │                        │         │  ◉             ◉       │
└──────────────┘                    └────────────────────────┘         │           ◉            │
   본인 1마리                        가족 최대 5마리                     │                        │
                                                                       └────────────────────────┘
                                                                          더 넓은 캔버스에 5마리
```

---

## 3. 기술 설계

### 3.1 타겟 구성

```
Mongle.xcworkspace
├─ Mongle (iOS App)                    [기존]
├─ Mongle-macOS (macOS 14+ App)        [신규]
├─ MongleWidgets (iOS Widget Ext)      [신규]
├─ MongleWidgets-mac (macOS Widget Ext)[신규, iOS와 소스 공유]
├─ MongleFeatures (SPM, iOS+macOS)     [기존]
├─ MongleData (SPM)                    [기존, App Group I/O 추가]
└─ MongleWidgetUI (SPM, 신규)          [위젯 전용 View, PhaseAnimator hop]
```

### 3.2 데이터 흐름 (CloudKit 없음, 정보 텍스트 없음)

```
┌──────────────────────────────────────────────┐
│  Mongle (iOS / macOS)                        │
│   HomeViewModel ──── 서버 API ────→ 서버     │
│       │                                       │
│       └─ 멤버/색 변경 시 ─→ WidgetStore.write │
└──────────────┬───────────────────────────────┘
               │
               ▼ (App Group, JSON < 1KB)
       ┌────────────────────┐
       │ scene.json         │  members[5], groupName 뿐
       └────────┬───────────┘
                │
                ▼ (read-only)
       ┌────────────────────┐
       │ MongleWidgets      │
       │  TimelineProvider  │
       │   5분마다 새 entry  │
       │   캐릭터 위치 변형  │
       └────────────────────┘
```

### 3.3 핵심 모듈

```swift
// MongleData/Sources/MongleData/Widget/WidgetSnapshot.swift  (신규)
public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let groupName: String        // 그룹 전환 감지용
    public let members: [WidgetMember]  // 최대 5명 (본인 + 활동 4명)
}

public struct WidgetMember: Codable, Equatable, Sendable {
    public let name: String
    public let colorHex: String
    public let isCurrentUser: Bool
    // hasAnswered 등은 MVP 후 결정. 처음에는 캐릭터 색/이름만.
}

// MongleData/Sources/MongleData/Widget/WidgetStore.swift  (신규)
public actor WidgetStore {
    public static let shared = WidgetStore(suite: "group.app.mongle.shared")
    public func write(_ snapshot: WidgetSnapshot) throws
    public func read() throws -> WidgetSnapshot?
}

// MongleWidgetUI/Sources/MongleWidgetUI/MongleWidgetEntry.swift
struct MongleEntry: TimelineEntry {
    let date: Date
    let members: [WidgetMember]
    let positions: [CGPoint]  // 이 entry 시점의 캐릭터 좌표 (정규화 0~1)
}

// MongleWidgetUI/Sources/MongleWidgetUI/MongleTimelineProvider.swift
struct MongleTimelineProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<MongleEntry>) -> Void) {
        guard let snap = try? WidgetStore.shared.readSync() else {
            completion(Timeline(entries: [.placeholder], policy: .after(.now.addingTimeInterval(300))))
            return
        }
        // 다음 60분치 entry를 5분 간격으로 미리 발행, 각 entry마다 위치를 simulate
        var entries: [MongleEntry] = []
        var positions = randomPositions(count: snap.members.count)
        for tick in 0..<12 {
            let date = Date().addingTimeInterval(Double(tick) * 300)
            entries.append(MongleEntry(date: date, members: snap.members, positions: positions))
            positions = stepPositions(positions)  // step() 로직 5분치 simulate
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
```

### 3.4 갱신 트리거

| 상황 | 동작 |
|---|---|
| 멤버 변경 / 색 변경 / 그룹 전환 | `WidgetStore.write()` + `WidgetCenter.reloadAllTimelines()` |
| 5분 경과 | TimelineProvider 가 미리 발행한 다음 entry로 자동 진행 |
| 60분 경과 (atEnd) | 시스템이 다시 `getTimeline` 호출 → 새 60분치 발행 |
| 메인 앱 HomeView appear | fallback으로 1회 write |

**메인 앱 `MongleSceneView.step()` 에는 어떤 hook도 안 건다.** 좌표는 위젯이 자체적으로 시뮬레이션.

### 3.5 위젯 안의 step() 미니 시뮬레이션

`MongleSceneView.step()` 의 단순화 버전을 `MongleWidgetUI`에 옮긴다. 시뮬레이션은 위젯 timeline 계산 시 한 번에 12번 (= 60분/5분) 돌려서 좌표 12세트를 만들고 entry에 박는다.

```swift
// 핵심 차이: 위젯에서는 60fps Timer가 없으므로 step 한 번 = 5분치 이동
// stepSize를 키워 위젯에서 캐릭터가 "5분에 한 번씩 다른 자리로" 옮겨가게 함
func stepPositions(_ positions: [CGPoint]) -> [CGPoint] {
    // 단순화: 각 캐릭터에 새 random target → 한 번에 target으로 60% 이동
    // 충돌 검사는 유지 (캐릭터 겹침 방지)
    ...
}
```

### 3.6 동기화 (간소)

- 모든 진실은 **서버 API**. 메인 앱이 fetch.
- 메인 앱이 fetch 끝나면 `WidgetSnapshot` 쓰고 reload.
- 위젯은 **App Group local read only**. 네트워크 사용 0.
- Mac도 동일. 서버 로그인은 기존 Apple Sign In 재사용.

---

## 4. 로드맵 (대폭 축소: 6주)

### Phase 0 — 파이프라인 검증 (3일)
- [ ] App Group entitlement 추가 (iOS)
- [ ] `WidgetSnapshot`, `WidgetStore` 스켈레톤
- [ ] 더미 위젯 (텍스트 "5명") 으로 read/write 검증
- **완료 기준**: 위젯에 더미 스냅샷 데이터가 보임

### Phase 1 — iOS 위젯 캐릭터 (2주)
- [ ] Widget Asset Catalog + 캐릭터 PNG 5색 (1x/2x/3x)
- [ ] systemSmall: 본인 캐릭터 1마리 + PhaseAnimator hop
- [ ] systemMedium: 최대 5마리 + 캐릭터별 위치 분산 + hop
- [ ] systemLarge: medium 확장
- [ ] TimelineProvider 5분 단위 entry 발행 + 좌표 simulate
- [ ] 위젯 탭 → `monggle://home` deep link
- **완료 기준**: 홈화면 위젯에 가족 캐릭터들이 통통 뛰며 시간 지날 때마다 다른 자리에 있음

### Phase 2 — macOS 앱 + 데스크탑 위젯 (2.5주)
- [ ] `Mongle-macOS` 타겟 (macOS 14 Sonoma) 추가
- [ ] HomeView `#if os(macOS)` 와이드 레이아웃 적용
- [ ] `onHover` 인터랙션 (캐릭터 scale + 점프)
- [ ] `MongleWidgets-mac` 타겟 — iOS 위젯 소스 재사용
- [ ] 데스크탑 위젯 탭 → Mac 앱 메인 윈도우 활성화
- **완료 기준**: Mac 앱에서 캐릭터들 뛰어다님, hover 반응, 데스크탑 위젯 동작

### Phase 3 — 다듬기 (1주)
- [ ] MenuBarExtra (옵션)
- [ ] 위젯에서 답변 여부 시각화 (글로우 vs 흐림) — 사용자 피드백 보고 결정
- [ ] 접근성: VoiceOver 라벨 ("Kim 가족, 5명")
- [ ] 메모리/배터리 측정 (Mac hover 디바운스 등)

**총 예상**: 5.5~6주 (혼자, 디자인 자산 외주 없이)

---

## 5. 즉시 다음 액션

**오늘 끝낼 수 있는 작업**:

1. `Mongle.entitlements`에 `com.apple.security.application-groups` 추가
2. `MongleData/Sources/MongleData/Widget/WidgetSnapshot.swift` 생성 — §3.3 코드 그대로
3. 메인 앱 `MongleApp.swift` 의 `MongleSceneView` 부모 또는 `HomeViewModel`에서 멤버 fetch 끝날 때 `WidgetStore.shared.write(...)` 한 줄

이게 끝나면 위젯 타겟 추가 + 텍스트 표시까지 30분이면 검증 완료.

---

## 6. 의도적으로 빼버린 것들

> 컨셉 단순화로 제거한 것 — 나중에 다시 넣을 수 있도록 기록만 남겨둠

| 제거 항목 | 이유 |
|---|---|
| 위젯에 텍스트 (오늘 질문, 답변 수, 스트릭) | 컨셉상 "정보 위젯" 회귀 |
| 인터랙티브 하트 버튼 (AppIntent) | 위젯이 도구화 됨, 캐릭터 감성 약화 |
| 이벤트 시각화 (✦/ring/🔥) | 캐릭터 모션이 메시지 자체 |
| Live Activity (질문 마감 임박) | 정보성. 알림으로 충분 |
| Control Widget (iOS 18+) | 위 동일 |
| 잠금화면 위젯 3종 | accessory는 텍스트 위주 → 컨셉과 어긋남. 후속 검토 |
| CloudKit | 서버 API로 충분 |
| 메인 앱 좌표 → 위젯 동기화 | 위젯이 자체 시뮬레이션 |
