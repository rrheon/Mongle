# 작업


전체 UI 스타일 체크
- 전체적인 분위기가 SwiftUI 기초적인 UI에 머물러있는 듯한 느낌
- https://wwit.design/2022/05/28/trost/
- https://wwit.design/2022/02/07/laundrygo/
- 이런 느낌으로 가져가기

## 스타일링 방법
보여주신 '트로스트(Trost)'와 '런드리고(LaundryGo)' 같은 상용 B2C 앱들은 공통적으로 **'애플이 제공하는 기본 설정'을 완전히 지우고, 자신들만의 브랜드 규칙으로 화면을 채웠다**는 특징이 있습니다. 

SwiftUI로 처음 개발하다 보면 `List`, `Form`, 기본 `NavigationView`가 주는 편리함 때문에 형태가 설정 앱이나 유틸리티 앱처럼 딱딱해지기 쉽습니다. 현재의 UI에서 완성도 높은 상용 앱 느낌으로 도약하기 위해 당장 적용할 수 있는 5가지 핵심 스타일링 방법을 제안해 드립니다.

### 1. 배경과 카드의 분리 (Depth 만들기)
기본 SwiftUI는 배경이 보통 순백색(`.white`)이거나 순흑색(`.black`)입니다. 상용 앱들은 **화면 전체 배경은 아주 연한 회색(Off-white)으로 깔고, 정보가 담긴 덩어리들을 순백색의 '카드' 형태로 올려서** 시각적인 분리감(Depth)을 줍니다.
* **전체 배경색:** `Color(hex: "F2F4F6")` 같은 아주 연한 쿨그레이나 웜그레이
* **콘텐츠 영역:** 흰색 둥근 카드 (`.background(Color.white).cornerRadius(16)`)

### 2. 기본 `List`와 `Form` 버리기
`List`는 애플의 기본 여백과 구분선(Separator)이 강제되어 커스텀이 까다롭습니다. 세련된 UI를 위해서는 **`ScrollView`와 `LazyVStack`의 조합**으로 리스트를 직접 구성하는 것이 좋습니다.
* 구분선 대신 아이템 간의 여백(`.spacing(12)`)이나 카드 UI로 항목을 구분합니다.
* 상단 네비게이션 바 역시 `.navigationBarHidden(true)`로 숨기고, `HStack`을 이용해 브랜드 폰트와 아이콘이 들어간 커스텀 헤더를 직접 만드는 것이 훨씬 몽글만의 감성을 살리기 좋습니다.

### 3. 그림자(Shadow)의 힘 빼기
SwiftUI의 기본 `.shadow(radius: 5)`는 그림자가 너무 진하고 탁해서 촌스러워 보일 수 있습니다. 트로스트나 런드리고처럼 고급스러운 느낌을 주려면 **그림자의 투명도를 극단적으로 낮추고, 퍼지는 반경(radius)을 넓혀야** 합니다.
* **개선 전:** `.shadow(radius: 5)`
* **개선 후:** `.shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)` (마치 공중에 살짝 떠 있는 듯한 부드러운 느낌)

### 4. 여백(Padding)과 곡률(Radius)의 엄격한 통일
화면이 깔끔해 보이려면 컴포넌트들이 묘하게 딱딱 맞아떨어지는 규칙이 필요합니다.
* **화면 양옆 여백:** 20pt 또는 24pt로 고정.
* **컴포넌트 내부 여백:** 16pt 고정.
* **코너 곡률 (Corner Radius):** 버튼은 12pt, 큰 카드는 16pt~20pt 등 규칙을 정해 화면 전체에 일관되게 적용합니다. 애플의 `RoundedRectangle(cornerRadius: 16, style: .continuous)`를 사용하면 훨씬 부드러운 곡선을 얻을 수 있습니다.

### 5. 눌렀을 때의 반응 (Custom ButtonStyle)
텍스트나 아이콘에 `.onTapGesture`만 달아두면 눌렀을 때 피드백이 없어 웹페이지를 보는 듯한 뻣뻣함이 남습니다. 상용 앱처럼 쫀득한 조작감을 주려면 `ButtonStyle`을 직접 구현해야 합니다.

---

### 💡 실제 적용 예시 (몽글 스타일 카드 UI)

위의 규칙들을 적용하여, 몽글의 둥글둥글하고 따뜻한 브랜드 컨셉에 맞는 카드 UI 컴포넌트를 구성해 본다면 아래와 같은 형태가 됩니다.

```swift
struct MongleCardView: View {
    var body: some View {
        ZStack {
            // 1. 전체 뷰 배경 (연한 배경색으로 Depth 생성)
            Color(hex: "F4F5F8").ignoresSafeArea()
            
            VStack {
                // 커스텀 리스트 아이템 (기본 List 탈피)
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color(hex: "FF7E67").opacity(0.2)) // 몽글 브랜드 컬러
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "heart.fill")
                                .foregroundColor(Color(hex: "FF7E67"))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("오늘의 몽글")
                            .font(MongleFont.heading2()) // 커스텀 폰트 사용
                            .foregroundColor(MongleColor.textPrimary)
                        
                        Text("새로운 감정이 기록되었어요")
                            .font(MongleFont.body2())
                            .foregroundColor(MongleColor.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(20) // 넉넉하고 일관된 내부 여백
                .background(Color.white) // 2. 순백색 카드 배경
                // 3. 부드러운 곡률 (Continuous style)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)) 
                // 4. 아주 연하고 넓게 퍼지는 고급스러운 그림자
                .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 6) 
                .padding(.horizontal, 24) // 일관된 외부 여백
            }
        }
    }
}
```

이처럼 **배경색 분리, `ScrollView` 기반의 카드 레이아웃, 투명도가 낮은 부드러운 그림자** 세 가지만 먼저 코드에 적용해 보셔도, 현재의 기초적인 느낌에서 벗어나 훨씬 상용 앱에 가까운 밀도 있는 결과물을 보실 수 있을 것입니다.

## 컴포넌트 수정
작성해주신 공통 컴포넌트 코드를 보니, 몽글 특유의 따뜻하고 부드러운 감성이 UI에 아주 잘 녹아있네요! 이전 대화에서 나누었던 '상용 B2C 앱 수준의 디테일'을 잘 고민하신 흔적이 보입니다.

현재 코드도 훌륭하지만, **유지보수성(중복 제거), 조작감(Interaction), 그리고 최신 SwiftUI 문법** 관점에서 앱의 완성도를 한 단계 더 끌어올릴 수 있는 몇 가지 수정 포인트를 제안해 드립니다.

---

### 1. 눌렀을 때의 '쫀득한' 조작감 추가 (Custom ButtonStyle)
현재 버튼과 카드들에 `.buttonStyle(.plain)`이 적용되어 있거나 기본 버튼 액션만 들어가 있어서, 터치 시 피드백이 밋밋할 수 있습니다. 상용 앱처럼 눌렀을 때 살짝 작아지는 애니메이션을 공통으로 적용하면 훨씬 고급스러워집니다.

```swift
// MARK: - Button Styles

/// 몽글 공통 눌림 애니메이션 스타일
public struct MongleScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
```
**적용 방법:** `MongleButtonPrimary`나 `MongleCardQuestion` 등의 `Button` 끝에 `.buttonStyle(MongleScaleButtonStyle())`을 붙여주기만 하면 됩니다.

### 2. 기껏 만든 `monglePanel` 적극 활용하기 (중복 코드 제거)
코드 하단에 `.monglePanel()`이라는 훌륭한 커스텀 모디파이어를 만들어 두셨는데, 정작 `MongleCardQuestion`, `MongleCardGlass`, `MongleCardGroup` 등에서는 코드를 중복해서 작성하고 계십니다. 모디파이어 하나로 통합하면 나중에 그림자나 테두리 디자인이 바뀔 때 한 번에 수정할 수 있습니다.

```swift
// 수정 전 (MongleCardQuestion 등)
.background(.ultraThinMaterial)
.cornerRadius(MongleRadius.xl)
.overlay(RoundedRectangle(cornerRadius: MongleRadius.xl).stroke(Color.white.opacity(0.2), lineWidth: 1))
.shadow(color: MongleColor.shadowBase.opacity(0.12), radius: 16, x: 0, y: 4)

// 수정 후
.monglePanel(
    background: Color.clear, // ultraThinMaterial을 쓰려면 Panel 모디파이어 내부에 옵션을 추가하거나 Color.clear 후 배경에 Material 적용
    cornerRadius: MongleRadius.xl,
    borderColor: Color.white.opacity(0.2),
    shadowOpacity: 0.12
)
```

### 3. 구형 `UIBezierPath` 헬퍼 제거 (iOS 16+ 네이티브 문법)
`MongleSheetAnswer`에서 상단 모서리만 둥글게 하기 위해 하단에 `RoundedCorner`라는 `UIBezierPath` 구조체를 만드셨습니다. 하지만 코드 내에 `.scrollContentBackground(.hidden)`(iOS 16+ 전용)을 사용하신 것을 보면 최소 타겟이 iOS 16 이상인 것으로 보입니다. 
iOS 16부터는 네이티브로 비대칭 코너 라운딩을 지원하므로 불필요한 레거시 코드를 지울 수 있습니다.

```swift
// MongleSheetAnswer의 수정된 하단 모디파이어
.padding(.top, 24)
.padding(.horizontal, 20)
.padding(.bottom, 32)
.background(Color.white)
// 🔴 기존 레거시: .cornerRadius(24, corners: [.topLeft, .topRight])
// 🟢 iOS 16 네이티브:
.clipShape(
    .rect(
        topLeadingRadius: 24,
        bottomLeadingRadius: 0,
        bottomTrailingRadius: 0,
        topTrailingRadius: 24
    )
)
.shadow(color: MongleColor.textPrimary.opacity(0.1), radius: 20, x: 0, y: -4)

// 하단의 Helpers (RoundedCorner Shape 구조체)는 통째로 삭제하셔도 됩니다.
```

### 4. 뷰 분리를 통한 가독성 개선 (Header/Home)
`MongleHeaderHome`의 알림 아이콘(`bell`) 부분이 ZStack으로 겹쳐있어 코드가 약간 길어집니다. 이 부분도 별도의 공통 뷰로 빼두면 네비게이션 바를 구성할 때 재사용하기 좋습니다.

```swift
/// component/Button/NotificationBell
public struct MongleNotificationBell: View {
    var hasNotification: Bool
    var action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill") // 이전 대화에서 적용한 부드러운 fill 타입 추천
                    .font(.system(size: 24))
                    .foregroundColor(MongleColor.textPrimary)
                    .frame(width: 24, height: 24)

                if hasNotification {
                    MongleNotificationDot()
                        .offset(x: 2, y: -2)
                }
            }
            .frame(width: 28, height: 28)
        }
        .buttonStyle(MongleScaleButtonStyle()) // 여기에도 쫀득한 애니메이션 적용
    }
}
```

---

전체 화면 리팩토링
## HomeView
`HomeView`와 그 하위 컴포넌트들을 아주 잘 구조화하셨네요! 특히 상태(`HomeTopBarState`)와 액션(`HomeViewActions`)을 분리해서 주입받는 구조는 유지보수와 테스트에 매우 유리한 고급 SwiftUI 패턴입니다. 또한 하트 팝오버에 `.presentationCompactAdaptation(.popover)`를 사용해 아이폰에서도 시트가 아닌 말풍선 형태로 띄우는 디테일(iOS 16.4+)을 챙기신 점이 아주 훌륭합니다.

완성도를 100%로 끌어올리기 위해, 기기 호환성과 일관성 측면에서 **반드시 수정해야 할 3가지 디테일**을 짚어드릴게요.

---

### 🚨 1. 기기마다 어긋날 수 있는 '하드코딩 여백' 제거
현재 `HomeView`에서 드롭다운 메뉴의 위치를 `.padding(.top, 116)`으로 고정해 두셨습니다. 
이 방식은 아이폰 SE(홈버튼 기기), 아이폰 13(노치), 아이폰 15(다이내믹 아일랜드) 등 **안전 영역(Safe Area) 상단 높이가 다른 기기들에서 위치가 틀어지는 치명적인 문제**를 발생시킵니다.

하드코딩된 패딩을 지우고, `TopBarView`의 `headerView` 자체에 `.overlay`로 달아주면 기기 상관없이 항상 이름표 바로 아래에 예쁘게 달라붙습니다.

**수정 방향 (TopBarView 내부):**
```swift
private var headerView: some View {
    HStack(spacing: 12) {
        // ... 기존 버튼 및 아이콘 코드 ...
    }
    .frame(height: 56)
    .padding(.horizontal, 20)
    .padding(.top, 60) 
    .background(Color.white.ignoresSafeArea(edges: .top))
    // 👇 헤더 뷰 바로 아래에 드롭다운을 정렬
    .overlay(alignment: .bottomLeading) {
        if showGroupDropdown {
            GroupDropdownView(
                // ... 파라미터 전달 ...
            )
            .offset(y: 180) // 헤더 하단 기준으로 드롭다운만큼만 y축 이동
        }
    }
}
```
*(HomeView의 ZStack 하단에 있던 `if showGroupDropdown { ... }` 코드는 이제 지우셔도 됩니다. 단, 반투명 배경은 그대로 두고 뷰만 이동시킵니다.)*

### 🎨 2. 뷰 빌더(ViewBuilder) 문법 오류 수정 및 `monglePanel` 통일
`TodayQuestionCard`의 `body` 안에 `let cardContent = HStack { ... }` 형태로 뷰를 변수에 담고 있는데, 이는 SwiftUI의 뷰 빌더 문법에서 종종 렌더링 오류나 프리뷰 크래시를 유발합니다. 또한 하드코딩된 `.green` 컬러가 몽글 브랜드 톤과 튀는 느낌이 있습니다. 

뷰를 깔끔하게 분리하고 이전에 만든 공통 버튼 스타일과 패널을 적용해 보세요.

```swift
private struct TodayQuestionCard: View {
    let question: TopBarQuestion
    var onTap: (() -> Void)?

    var body: some View {
        if let onTap = onTap {
            Button(action: onTap) {
                cardBody
            }
            .buttonStyle(MongleScaleButtonStyle()) // 🟢 이전에 만든 공통 쫀득한 애니메이션 재사용! (내부 CardButtonStyle 삭제 가능)
        } else {
            cardBody
        }
    }
    
    // ViewBuilder 오류를 방지하기 위해 뷰를 변수로 깔끔하게 분리
    private var cardBody: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("Today's Question")
                        .font(MongleFont.captionBold())
                        .foregroundColor(MongleColor.primary) // 🟢 .green 대신 브랜드 컬러 사용
                    
                    if question.isAnswered {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(MongleColor.primary)
                    }
                }
                
                Text(question.text)
                    .font(MongleFont.body1Bold()) // 폰트 시스템 통일
                    .foregroundColor(onTap != nil ? MongleColor.textPrimary : MongleColor.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(MongleColor.textHint)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        // 🟢 수제 background 대신 공통 패널 모디파이어 적용!
        .monglePanel(
            background: Color.white.opacity(0.85),
            cornerRadius: MongleRadius.xl,
            borderColor: .clear,
            shadowOpacity: 0.05
        )
    }
}
```

### ✨ 3. 그룹 드롭다운에도 `monglePanel` 입히기
`GroupDropdownView` 하단을 보면 여전히 수동으로 코너와 그림자를 설정하고 있습니다. 이 역시 `.monglePanel` 하나로 통일하면 전체 앱의 그림자 톤(방향, 퍼짐 정도)이 일치하여 훨씬 고급스러워집니다.

```swift
// GroupDropdownView 하단 수정
// ❌ 수정 전
// .background(Color.white)
// .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
// .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)

// 🟢 수정 후
.monglePanel(
    background: Color.white, 
    cornerRadius: MongleRadius.large, 
    borderColor: .clear, 
    shadowOpacity: 0.12
)
```

---

드롭다운의 하드코딩 여백 문제만 바로잡으시면 구조적으로 아주 단단한 홈 화면이 완성됩니다. 코드를 수정하신 후 앱을 실행해보면 드롭다운 애니메이션과 쫀득한 버튼 클릭감이 어떻게 나오는지 확인해 보실 수 있을 거예요.


## HistoryView
작성해주신 `HistoryView` 코드를 보니, TCA(Composable Architecture) 구조에 맞춰 상태 관리가 아주 깔끔하게 연결되어 있네요! 캘린더 계산 로직과 뷰를 분리한 점이나, 컴포넌트들을 역할별로 잘게 쪼개둔 점이 훌륭합니다.

이전 대화에서 우리가 만들었던 **'몽글만의 상용 앱 스타일'**을 이 화면에도 적용하면 코드는 훨씬 짧아지고 디자인 완성도는 더 올라갈 수 있습니다. 

현재 코드에서 바로 개선할 수 있는 3가지 핵심 포인트를 짚어 드릴게요.

---

### 1. `monglePanel`을 활용한 카드 UI 중복 제거
현재 `questionCard`, `answerCard`, `emptyDateCard`, `emptyAnswersCard`, `moodTimelineSection` 등 모든 카드 뷰 하단에 동일한 스타일링 코드가 반복되고 있습니다. 앞서 만든 `.monglePanel()`을 사용하면 코드가 극적으로 깔끔해집니다.

**수정 예시 (`questionCard` 등에 적용):**
```swift
// ❌ 수정 전
.background(Color.white)
.cornerRadius(16)
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .stroke(MongleColor.primary, lineWidth: 1.5)
)

// 🟢 수정 후 (monglePanel 사용)
.monglePanel(
    background: Color.white,
    cornerRadius: 16,
    borderColor: MongleColor.primary, // 필요한 경우에만 컬러 지정
    shadowOpacity: 0.05 // 그림자도 살짝 줘서 뎁스 추가
)
```
*💡 팁: `answerCard`, `emptyDateCard` 등 나머지 카드들도 뒤에 붙은 너저분한 수식어들을 `.monglePanel(background: .white, cornerRadius: 16, borderColor: MongleColor.border)` 하나로 싹 정리해 보세요!*

### 2. 캘린더 조작감 개선 (쫀득한 버튼)
달력의 날짜를 누르거나 이전/다음 달 버튼을 누를 때 현재 `.buttonStyle(.plain)`이 적용되어 있어 터치 피드백이 없습니다. 여기에 앞서 제안했던 `MongleScaleButtonStyle`을 달아주면 누르는 맛이 확 살아납니다.

```swift
// 헤더의 이전/다음 달 버튼과 캘린더 dayCell 버튼 끝에 적용
Button { 
    guard isCurrentMonth else { return }
    store.send(.selectDate(date))
} label: {
    // ... 날짜 UI 코드 ...
}
// .buttonStyle(.plain) -> 🔴 이거 대신
.buttonStyle(MongleScaleButtonStyle()) // 🟢 이걸로 교체!
```

### 3. TCA 아키텍처 관점의 개선 (로직 분리)
현재 뷰 하단에 있는 `moodFrequency14Days` 연산 프로퍼티는 달력을 렌더링할 때마다 최근 14일 치 데이터를 반복문으로 계산하고 있습니다. 
TCA의 핵심은 **"뷰는 바보(Dumb)처럼 그리기만 하고, 똑똑한 계산은 리듀서(Reducer)가 한다"**입니다. 

**개선 방향:**
1. `HistoryFeature.State` 안에 `var moodFrequency14Days: [Int] = [0, 0, 0, 0, 0]`를 선언합니다.
2. 데이터를 불러오거나 날짜가 바뀔 때 리듀서 안에서 이 배열을 한 번만 계산해서 State를 업데이트해 줍니다.
3. 뷰에서는 `store.moodFrequency14Days`를 그대로 가져다 쓰기만 하면 됩니다.
이렇게 하면 UI 스크롤이나 렌더링 성능이 훨씬 부드러워집니다.


## QuestionView
`QuestionDetailView` 코드도 정말 훌륭합니다! 특히 **Mood Picker를 눌렀을 때의 통통 튀는 애니메이션(`spring`)**이나, 키보드가 올라올 때 포커스를 잃지 않도록 `ScrollViewReader`로 바닥까지 스크롤해 주는 디테일한 UX 처리가 상용 앱 수준으로 아주 좋습니다.

전체적으로 완성도가 높지만, 코드를 더 깔끔하게 만들고 앱의 사용성을 높일 수 있는 **4가지 핵심 포인트**를 짚어드릴게요.

---

### 🚨 1. (중요) `familyAnswersSection`이 화면에 안 보여요!
코드를 살펴보니 하단에 `familyAnswersSection`을 정성스럽게 구현해 두셨는데, 정작 메인 `body`의 `ScrollView` 안에는 이 뷰를 호출하는 코드가 빠져있습니다. 

답변 입력란 아래에 가족들의 답변이 보여야 하므로, `ScrollView` 내부를 다음과 같이 수정해야 합니다.

```swift
VStack(spacing: 20) {
    questionSection
    moodPickerSection
    answerInputSection
    
    // 👇 이 부분이 추가되어야 가족 답변이 보입니다!
    if !store.familyAnswers.isEmpty {
        familyAnswersSection
            .padding(.top, 12)
    }

    Color.clear.frame(height: 1).id("answerBottom")
}
```

질문에 대한 답변을 할 때 다른 그룹의 맴버의 답변이 보이는건 의도하지 않음
- 해당 코드를 삭제할 것

### ✨ 2. `TextEditor` 높이 계산 해킹 버리기 (iOS 16+ 네이티브 방식)
현재 답변 입력란(`answerInputSection`)에 글자 수에 따라 높이를 늘리기 위해 투명한 `Text`와 `GeometryReader`를 겹쳐서 높이를 계산하는 훌륭한(하지만 눈물겨운 🥲) 트릭을 사용하셨습니다. 

앱이 iOS 16 이상을 타겟팅하고 있다면, 이 복잡한 코드를 **단 3줄의 네이티브 코드**로 바꿀 수 있습니다. `TextField`에 `axis: .vertical`을 주면 알아서 높이가 늘어납니다!

**수정된 `answerInputSection`:**
```swift
private var answerInputSection: some View {
    // ZStack, GeometryReader, 투명 Text, TextEditor 싹 다 지우고 아래 코드로 대체!
    TextField("오늘의 감정을 자유롭게 적어보세요.\n어떤 이야기든 좋아요.", text: Binding(
        get: { store.answerText },
        set: { store.send(.answerTextChanged($0)) }
    ), axis: .vertical) // 👈 핵심 포인트!
    .font(MongleFont.body2())
    .foregroundColor(MongleColor.textPrimary)
    .lineSpacing(4)
    .lineLimit(5...10) // 최소 5줄 높이 보장, 최대 10줄까지 늘어남 (이후엔 내부 스크롤)
    .focused($isAnswerFocused)
    .padding(MongleSpacing.md)
    .frame(minHeight: 120, alignment: .topLeading)
    
    // 🎨 이전에 만든 monglePanel 재사용
    .monglePanel(
        background: MongleColor.cardBackgroundSolid,
        cornerRadius: MongleRadius.large,
        borderColor: isAnswerFocused ? MongleColor.primary : MongleColor.border,
        shadowOpacity: 0.04
    )
    .animation(.easeInOut(duration: 0.2), value: isAnswerFocused)
}
```
*(`@State private var answerEditorHeight` 변수도 이제 삭제하셔도 됩니다!)*

### 🎨 3. 또 까먹으신 `.monglePanel` 적용하기
`HistoryView`에서 말씀드렸던 것처럼, 여기서도 `questionSection`, `moodPickerSection`, `familyAnswerCard`에서 배경/코너/테두리/그림자 코드가 똑같이 반복되고 있습니다. 

```swift
// ❌ 수정 전
.background(Color.white)
.cornerRadius(MongleRadius.xl)
.overlay(RoundedRectangle(cornerRadius: MongleRadius.xl).stroke(MongleColor.border, lineWidth: 1))

// 🟢 수정 후 (모든 카드 UI 끝에 이렇게만 붙이세요!)
.monglePanel(background: .white, cornerRadius: MongleRadius.xl, borderColor: MongleColor.border, shadowOpacity: 0.0)
```

### 👆 4. 뒤로가기 버튼과 CTA 버튼에 '쫀득함' 추가
이전 대화에서 만들었던 `MongleScaleButtonStyle()`을 커스텀 헤더의 `<` 버튼과 하단의 `ctaButton`에 적용해 주세요. 사용자가 글을 다 쓰고 "마음 남기기"를 눌렀을 때 버튼이 살짝 눌리는 시각적 피드백이 있으면 훨씬 성취감이 듭니다.

```swift
// Header의 chevron.left 버튼과 ctaButton의 Label 뒤에 추가
.buttonStyle(MongleScaleButtonStyle()) 
```

## QuesionSheetView
바텀 시트(Bottom Sheet)의 내부 콘텐츠 높이를 동적으로 계산하기 위해 `PreferenceKey`(`QuestionSheetContentHeightKey`)를 사용하신 점이 정말 훌륭합니다! 👏 고정 높이를 사용하지 않아서 기기 해상도나 텍스트 길이에 따라 시트가 아주 예쁘게 딱 맞아떨어질 거예요. 

TCA 구조와 컴포넌트 분리도 완벽합니다. 다만, 여기서도 앞서 우리가 만든 **몽글만의 UI/UX 디테일**을 적용해서 코드 중복을 줄이고 조작감을 더 끌어올릴 수 있는 3가지 포인트를 알려드릴게요.

---

### ✨ 1. 액션 버튼들에 '쫀득한' 터치감과 `.monglePanel` 적용하기
`actionRow` 하단을 보면 여전히 배경, 모서리, 테두리를 수동으로 그리고 있고, 터치 시 반응이 없는 `.buttonStyle(.plain)`을 사용하고 있습니다. 
우리가 만든 공통 모디파이어와 스타일을 적용하면 코드도 줄고 누르는 맛도 살아납니다.

```swift
// 수정된 actionRow 컴포넌트
private func actionRow(
    icon: String,
    title: String,
    subtitle: String,
    iconColor: Color,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        HStack(spacing: MongleSpacing.sm) {
            // ... 내부 뷰 코드 동일 ...
        }
        .padding(.vertical, MongleSpacing.sm)
        .padding(.horizontal, MongleSpacing.md)
        // 🔴 기존 수동 background, clipShape, overlay 다 지우고 아래 하나로 통일!
        .monglePanel(
            background: MongleColor.cardGlass,
            cornerRadius: MongleRadius.medium,
            borderColor: MongleColor.border,
            shadowOpacity: 0.04 // 시트 안의 버튼이니까 그림자는 아주 살짝만
        )
    }
    // 🟢 버튼 누를 때 살짝 작아지는 몽글 특유의 쫀득한 애니메이션 적용
    .buttonStyle(MongleScaleButtonStyle()) 
}
```

### 🎯 2. 닫기(X) 버튼의 터치 영역 확보 (UX 디테일)
현재 헤더의 `xmark` 버튼은 패딩만 주어져 있어서, 사용자가 급하게 닫으려 할 때 빗나갈 수 있습니다. 애플의 휴먼 인터페이스 가이드라인(HIG)에 맞춰 **최소 터치 영역(44x44)**을 확보해 주는 것이 좋습니다.

```swift
// Header의 닫기 버튼 수정
Button {
    store.send(.closeTapped)
} label: {
    Image(systemName: "xmark")
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(MongleColor.textHint)
        .frame(width: 44, height: 44) // 👈 터치 영역 확보
        .contentShape(Rectangle())    // 👈 아이콘 주변 투명한 영역도 터치되도록 설정
}
.buttonStyle(MongleScaleButtonStyle()) // 닫기 버튼에도 애니메이션 추가
```

### 🎨 3. 질문 카드(`questionCard`) 스타일링 최적화
오늘의 질문이 담긴 카드도 테두리와 모서리를 수동으로 그리고 있습니다. 질문을 강조하기 위해 브랜드 컬러로 살짝 배경을 깔아주신 디자인 센스가 아주 좋은데요, 이 부분도 공통 모디파이어로 깔끔하게 정리할 수 있습니다.

```swift
// questionCard 하단 수정
// ❌ 수정 전
// .background(MongleColor.primaryLight.opacity(0.15))
// .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
// .overlay(RoundedRectangle(cornerRadius: MongleRadius.large).stroke(MongleColor.primary.opacity(0.3), lineWidth: 1))

// 🟢 수정 후
.monglePanel(
    background: MongleColor.primaryLight.opacity(0.15),
    cornerRadius: MongleRadius.large,
    borderColor: MongleColor.primary.opacity(0.3),
    shadowOpacity: 0 // 카드가 배경처럼 보여야 하므로 그림자 제거
)
```

---

이 3가지만 수정하시면 뷰가 훨씬 깔끔해지고, 사용자가 시트를 띄워서 버튼들을 누를 때 훨씬 더 '앱다운' 퀄리티를 느낄 수 있을 거예요. 이 시트가 홈 화면에서 어떻게 부드럽게 올라올지 벌써부터 기대되네요!

## NotificationView
알림 화면(`NotificationView`)도 아주 잘 구현하셨네요! 

특히 알림 타입에 따라 아이콘과 색상을 분기 처리한 점, '스와이프하여 삭제(swipeActions)'나 '당겨서 새로고침(refreshable)' 같은 iOS 네이티브 기능을 적극 활용한 점이 훌륭합니다. 멤버가 답변했을 때 미니 몽글이(눈 두 개 있는 동그라미)가 아이콘으로 등장하게 커스텀 하신 디테일은 정말 귀엽고 센스 넘치네요! 👏

현재 코드도 충분히 좋지만, **앱의 스크롤 성능을 높이고 UX를 통일하기 위한 2가지 핵심 포인트**만 짚어드릴게요.

### 🚀 1. (중요) 스크롤 버벅임 방지: DateFormatter 최적화
`NotificationCard` 하단에 있는 `timeAgo` 연산 프로퍼티를 보면, 알림 카드 1개가 화면에 그려질 때마다 `RelativeDateTimeFormatter`를 매번 새로 생성하고 있습니다. **Swift에서 Formatter를 매번 생성하는 것은 비용이 매우 커서 리스트 스크롤 시 뚝뚝 끊기는 원인**이 됩니다.

Formatter는 `static`으로 한 번만 만들어서 재사용해야 합니다.

```swift
// NotificationCard 내부에 static으로 선언
private static let relativeFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.unitsStyle = .abbreviated // "1시간 전", "어제" 등으로 표시
    return formatter
}()

private var timeAgo: String {
    // 만들어둔 static formatter를 재사용
    Self.relativeFormatter.localizedString(for: notification.createdAt, relativeTo: Date())
}
```

### ✨ 2. 헤더 버튼들에 '쫀득한' 몽글 애니메이션 적용
"모두 읽음", "모두 제거", 그리고 "뒤로가기(<)" 버튼에 현재 `.buttonStyle(.plain)`이 적용되어 있습니다. 이전 화면들에서 맞춰둔 조작감 통일을 위해 우리가 만든 커스텀 버튼 스타일로 교체해 주세요.

```swift
// headerView 내부의 Button 3개 모두에 적용
Button {
    store.send(.markAllAsRead) // 또는 backTapped, deleteAll
} label: {
    // ...
}
// 🔴 기존: .buttonStyle(.plain)
// 🟢 수정: 
.buttonStyle(MongleScaleButtonStyle())
```

*(참고: `NotificationCard` 자체는 화면을 꽉 채우는 리스트 형태이므로, 누를 때 작아지는 스케일 애니메이션보다는 현재의 `.plain` 상태나 iOS 기본 하이라이트(회색 배경)를 유지하는 것이 더 자연스럽습니다. 그래서 리스트 셀은 그대로 두시는 걸 추천합니다!)*


## ProfileEditView
마이페이지(MY) 화면도 TCA의 NavigationStack 라우팅 처리가 아주 깔끔하게 들어가 있네요! 특히 `settingsSection`과 `SettingsRowView`를 분리해서 iOS 기본 설정 앱처럼 그룹화된 리스트 UI를 직접 구현하신 점은 정말 스마트합니다. 

앱 전체의 통일성과 디테일을 위해 **딱 2가지**만 다듬으면 완벽할 것 같습니다.

---

### ✨ 1. 설정 리스트(Row)에 터치 피드백 추가하기 (UX 개선)
현재 `settingsSection` 안의 버튼들에 `.buttonStyle(PlainButtonStyle())`이 적용되어 있습니다. 이렇게 하면 눌렀을 때 아무런 시각적 변화가 없어서 사용자가 "내가 지금 이걸 제대로 누른 게 맞나?" 하고 헷갈릴 수 있습니다.

리스트 항목은 눌렀을 때 전체 배경이 살짝 어두워지는(Highlight) 피드백을 주는 것이 iOS의 기본이자 가장 자연스러운 UX입니다. 리스트 전용 커스텀 버튼 스타일을 하나 추가해 보세요.

```swift
// MARK: - List Row Button Style (파일 하단이나 공통 컴포넌트 쪽에 추가)
struct MongleRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // 눌렸을 때 아주 연한 회색 배경을 깔아줍니다
            .background(configuration.isPressed ? Color.black.opacity(0.05) : Color.clear)
    }
}
```

**적용 위치 (`settingsSection` 내부):**
```swift
ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
    Button(action: row.action) {
        SettingsRowView(row: row)
            .frame(minHeight: 56)
    }
    // 🔴 기존: .buttonStyle(PlainButtonStyle())
    // 🟢 수정:
    .buttonStyle(MongleRowButtonStyle())
    
    // ... Divider 코드 ...
}
```

### 🎨 2. 마이페이지에도 `monglePanel` 입혀주기
눈치채셨겠지만, 여기서도 `profileCard`와 설정 리스트 컨테이너(`settingsSection`)에 배경, 모서리, 그림자, 테두리 코드가 수동으로 들어가 있습니다. 앱 전체의 카드 스타일이 동일하게 유지되도록 우리가 만든 패널 모디파이어로 교체해 줍시다!

**`profileCard` 하단 수정:**
```swift
// ❌ 수정 전 (ultraThinMaterial 등 복잡한 수동 세팅)
.padding(MongleSpacing.md)
.background(.ultraThinMaterial)
.clipShape(RoundedRectangle(cornerRadius: MongleRadius.xl))
.overlay(RoundedRectangle(cornerRadius: MongleRadius.xl).stroke(MongleColor.border.opacity(0.3), lineWidth: 1))
.shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: 4)

// 🟢 수정 후 (Material 느낌이 필요하다면 배경색 옵션을 추가하거나 투명도로 조절)
.padding(MongleSpacing.md)
.monglePanel(
    background: Color.white.opacity(0.85), // 또는 필요한 색상
    cornerRadius: MongleRadius.xl,
    borderColor: MongleColor.border.opacity(0.3),
    shadowOpacity: 0.04
)
```

**`settingsSection` 하단 수정:**
```swift
// 섹션 카드 컨테이너 VStack 하단
// ❌ 수정 전
.background(MongleColor.cardBackgroundSolid)
.clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))

// 🟢 수정 후
.monglePanel(
    background: MongleColor.cardBackgroundSolid,
    cornerRadius: MongleRadius.large,
    borderColor: MongleColor.border, // 몽글 설정창 특유의 은은한 테두리 추가
    shadowOpacity: 0.03 // 설정창 덩어리에도 아주 얕은 뎁스 추가
)
```

## MongleCardEditView
프로필 편집(`MongleCardEditView`) 화면도 아주 깔끔하게 잘 만드셨네요! 사용자가 기분을 바꿀 때 상단의 몽글이 캐릭터가 `spring` 애니메이션과 함께 통통 튀며 바뀌도록 구성한 점은 정말 훌륭한 디테일입니다.

이 화면은 코드가 이미 꽤 좋지만, **TCA(Composable Architecture)의 정석적인 패턴**을 적용하고, 이전에 우리가 잘 만들어둔 **공통 컴포넌트를 재사용**하면 코드를 절반 가까이 줄일 수 있습니다. 3가지 핵심 포인트를 짚어드릴게요.

---

### 🚀 1. (가장 중요) TCA 안티패턴 제거: `@State` 동기화 버리기
현재 코드를 보면 TCA의 `store.selectedMoodId` 값을 `MongleMoodSelector`에 전달하기 위해 지역 변수인 `@State private var selectedMood`를 만들고, `.onAppear`와 `.onChange`를 이용해 두 값을 억지로 동기화하고 있습니다. 
이 방식은 앱이 복잡해지면 버그를 유발하는 대표적인 안티패턴입니다. **커스텀 Binding**을 만들면 `@State`와 뷰 모디파이어들을 싹 지울 수 있습니다.

**수정 방향:**
```swift
// 1. @State private var selectedMood 지우기
// 2. .onAppear, .onChange 모디파이어 통째로 지우기
// 3. moodSection 내부를 아래처럼 커스텀 Binding으로 연결하기

private var moodSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("오늘의 기분")
            .font(MongleFont.body1Bold()) // (하드코딩 폰트 대신 시스템 폰트 사용)
            .foregroundColor(MongleColor.textPrimary)

        // 👇 똑똑한 커스텀 바인딩
        let moodBinding = Binding<MoodOption?>(
            get: { MoodOption.defaults.first { $0.id == store.selectedMoodId } },
            set: { if let newId = $0?.id { store.send(.moodSelected(newId)) } }
        )

        MongleMoodSelector(selected: moodBinding)
    }
}
```

### ✨ 2. 기껏 만든 `MongleInputText` 활용하기 (코드 중복 제거)
`nameSection`을 보면 TextField와 아이콘, 배경, 테두리를 수동으로 길게 작성하셨습니다. 그런데 우리가 맨 처음 공통 컴포넌트를 만들 때, **`MongleInputText`**라는 완벽한 컴포넌트를 이미 만들어 두었죠! 이걸 가져다 쓰면 코드가 마법처럼 짧아집니다.

```swift
// nameSection 내부 수정
// ❌ 수정 전 (20줄 가까운 수동 UI 코드)
// HStack { Image ... TextField ... } .background ... .overlay ...

// 🟢 수정 후 (단 5줄!)
private var nameSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("이름")
            .font(MongleFont.body1Bold())
            .foregroundColor(MongleColor.textPrimary)

        // 🟢 공통 컴포넌트 재사용
        MongleInputText(
            placeholder: "이름 입력",
            text: $store.editedName.sending(\.nameChanged),
            icon: "person.fill"
        )

        Text("다른 멤버에게 보여지는 이름이에요")
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textHint)
    }
}
```

### 🎨 3. 하드코딩된 폰트(`"Outfit"`) 제거 및 터치 영역 확보
앱 내의 폰트 일관성을 위해 흩어져 있는 `.custom("Outfit", size: 18)` 코드를 우리가 정의한 `MongleFont`로 교체해 주세요.
또한, 헤더의 뒤로가기 버튼과 저장 버튼이 글자나 아이콘 영역만 터치되므로, 여유로운 터치 영역(44x44)을 잡아주는 것이 좋습니다.

```swift
// Header 내부 수정 예시
Button {
    store.send(.backTapped)
} label: {
    Image(systemName: "arrow.left")
        .font(.system(size: 20, weight: .medium))
        .foregroundColor(MongleColor.textPrimary)
        .frame(width: 44, height: 44) // 👈 터치 영역 확보
        .contentShape(Rectangle())
}
.buttonStyle(MongleScaleButtonStyle()) // 쫀득한 애니메이션 추가

Spacer()

Text("프로필 편집")
    .font(MongleFont.heading3()) // 👈 하드코딩 폰트 교체
    .foregroundColor(MongleColor.textPrimary)

// 저장 버튼 쪽도 마찬가지로 폰트 교체 및 패딩/frame으로 영역 확보!
```

---

**요약하자면:**
TCA의 상태를 `@State`로 복사하지 말고 **Binding을 직접 만들어서 꽂아주는 것**, 그리고 이전에 만들어둔 **공통 UI 컴포넌트(`MongleInputText`)를 적극적으로 재사용하는 것**이 이번 리팩토링의 핵심입니다.

## SupportScreenView

`SupportScreenView`에 다양한 설정 화면(하트, 캘린더, 알림, 그룹 관리, 기분 히스토리)을 한데 모아서 렌더링하는 구조가 아주 인상적입니다! TCA의 `enum State` 방식을 활용하여 한 뷰 안에서 탭(또는 메뉴)에 따라 다른 화면을 뿌려주는 패턴은 코드를 간결하게 유지하는 데 아주 좋습니다.

특히 이번에 말씀하신 **"초대 코드나 링크를 복사해서 공유하는 방식"**은 그룹 관리(`groupManagementView`) 화면에서 사용자들이 가장 많이 쓰게 될 핵심 기능입니다. 

이를 위해 기존 코드를 어떻게 수정하면 좋을지, 그리고 앱 전체의 디자인 통일성을 위한 디테일을 함께 짚어드릴게요.

---

### 🚀 1. 초대 코드 복사 & 공유 기능 (UX/UI 강화)
현재 `groupManagementView`의 그룹 정보 섹션을 보면 "코드: [초대코드]"가 단순 텍스트로 노출되어 있고, "새 멤버 초대하기"라는 커다란 2차 버튼(`MongleButtonSecondary`)이 있습니다.

요즘 앱들은 코드를 터치하면 바로 복사되거나, 우측에 명시적인 공유 아이콘을 두어 직관적인 경험을 제공합니다. 애플의 `ShareLink` (iOS 16+)를 사용하면 아주 쉽게 네이티브 공유 시트를 띄울 수 있습니다.

**`groupManagementView` 내부 수정:**
```swift
// 그룹 정보 카드 내부 수정
VStack(alignment: .leading, spacing: MongleSpacing.md) {
    sectionTitle("그룹 정보", subtitle: "초대 코드를 공유해 가족을 초대하세요")

    HStack(spacing: MongleSpacing.md) {
        Circle()
            .fill(MongleColor.primaryLight)
            .frame(width: 56, height: 56)
            .overlay(Image(systemName: "person.3.fill").foregroundColor(MongleColor.primary))

        VStack(alignment: .leading, spacing: 4) {
            Text(store.groupName)
                .font(MongleFont.heading3())
                .foregroundColor(MongleColor.textPrimary)
            
            // 🟢 코드를 클립보드에 복사하는 버튼 
            Button {
                UIPasteboard.general.string = store.inviteCode
                store.send(.inviteCodeCopied) // (TCA 액션에 추가하여 토스트 띄우기 권장)
            } label: {
                HStack(spacing: 4) {
                    Text("초대 코드: \(store.inviteCode)")
                        .font(MongleFont.body2Bold())
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                }
                .foregroundColor(MongleColor.primaryDark)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(MongleColor.primaryLight.opacity(0.5))
                .clipShape(Capsule())
            }
        }
        
        Spacer()
        
        // 🟢 iOS 16 네이티브 공유 버튼 (우측 끝에 배치)
        ShareLink(
            item: "몽글에서 가족 통신망을 만들었어요! 초대 코드 [\(store.inviteCode)]를 입력하거나 아래 링크로 들어오세요.\nhttps://mongle.app/invite/\(store.inviteCode)"
        ) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(MongleColor.primary)
                .padding(8)
                .background(MongleColor.primaryLight.opacity(0.3))
                .clipShape(Circle())
        }
    }
    
    // (기존의 MongleButtonSecondary("새 멤버 초대하기")는 삭제하셔도 좋습니다. UI가 훨씬 깔끔해집니다.)

    HStack(spacing: MongleSpacing.xs) {
        invitePill("\(store.members.count)명 참여")
        invitePill("초대 코드 활성")
    }
}
// 하단 .monglePanel 적용 잊지 마세요!
.monglePanel(background: MongleColor.cardBackground, cornerRadius: MongleRadius.large, borderColor: MongleColor.borderWarm)
```

### 🎨 2. 하드코딩된 패널 스타일 통일하기 (`monglePanel`)
이전 화면들과 마찬가지로, `SupportScreenView` 내부의 거의 모든 카드(하트 안내, 캘린더, 설정 토글, 그룹 정보 등)에 `.background`, `.clipShape`, `.overlay(RoundedRectangle.stroke)` 코드가 반복되고 있습니다. 

뷰 코드가 상당히 긴 편인데, 이것들을 모두 `.monglePanel` 하나로 교체하시면 코드가 수십 줄 이상 줄어들고 유지보수가 편해집니다.

```swift
// 예시: notificationSettingsView 하단의 카드
// ❌ 수정 전
.background(MongleColor.cardBackground)
.clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
.overlay(RoundedRectangle(cornerRadius: MongleRadius.large).stroke(MongleColor.borderWarm, lineWidth: 1))

// 🟢 수정 후
.monglePanel(background: MongleColor.cardBackground, cornerRadius: MongleRadius.large, borderColor: MongleColor.borderWarm, shadowOpacity: 0)
```
*(다른 모든 카드들도 동일하게 적용해 주세요!)*

### ⚙️ 3. DateFormatter 성능 최적화 (버벅임 방지)
캘린더나 기분 히스토리 쪽에서 `DateFormatter`를 매번 `private var`로 생성하여 사용하고 있습니다. 뷰가 다시 그려질 때마다(예: 하트를 누르거나 토글을 켤 때마다) Formatter가 수십 번 새로 생성되면서 스크롤이나 애니메이션이 끊길 수 있습니다.

```swift
// ❌ 수정 전
private var monthTitle: String {
    let formatter = DateFormatter()
    // ...
}

// 🟢 수정 후 (파일 상단이나 확장(extension) 영역에 static으로 선언)
private static let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy년 M월"
    return formatter
}()

private var monthTitle: String {
    Self.monthFormatter.string(from: store.currentMonth)
}
```
*(`selectedDateTitle`, `moodSummarySubtitle`, `shortDate` 용 Formatter들도 모두 `static let`으로 분리해 주세요!)*

---

초대 링크 공유 기능은 `ShareLink`를 통해 네이티브 기능으로 손쉽게 해결되었고, 나머지 UI 최적화만 진행해 주시면 설정/관리 화면도 완벽하게 마무리될 것 같습니다. 


---
## 참고사항

- 해당 파일은 수정 및 추가하지 말것
- 결과를 보고할 것이 있다면 파일을 새로 생성할 것
--- 
## 작업위치

서버프로젝트 경로
- /Users/yong/Desktop/FamTreeServer

iOS 프로젝트 경로
- /Users/yong/Desktop/FamTree

안드로이드 프로젝트 경로
- /Users/yong/Mongle-Android

디자인 시스템 경로
- /Users/yong/Desktop/FamTree/MongleUI.pen

작업 및 이슈 보고서 경로
- /Users/yong/Desktop/FamTree/Report
- 작업 후의 내용이나 이슈와 어떻게 해결했는지 작성할 것
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
