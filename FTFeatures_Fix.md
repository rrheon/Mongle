# FTFeatures 모듈 분리 시 발생한 문제 및 해결 방법

## 개요

FamTree 프로젝트에서 FTFeatures를 별도 Swift Package로 분리하면서 발생한 문제들과 해결 방법을 정리합니다.

---

## 발생한 문제들

### 1. Swift/iOS 버전 불일치

**문제:**
```
Domain, FTData: Swift 5.9, iOS 15+
FTFeatures: Swift 6.2, iOS 18 only
```

다른 패키지들과 Swift tools 버전 및 플랫폼 버전이 일치하지 않아 빌드 시 호환성 문제가 발생할 수 있었습니다.

**해결:**
```swift
// FTFeatures/Package.swift
// Before
// swift-tools-version: 6.2
// platforms: [.iOS(.v18)]

// After
// swift-tools-version: 5.9
// platforms: [.iOS(.v17), .macOS(.v14)]
```

> **주의:** iOS 17로 설정한 이유는 코드에서 `NavigationStack`, SwiftUI `@Bindable` 등 iOS 16+ API를 사용하기 때문입니다.

---

### 2. FTData 의존성 누락

**문제:**
FTFeatures가 FTData를 import하지 않아 실제 데이터 레이어(Repository)와 연결되지 않았습니다.

**해결:**
```swift
// FTFeatures/Package.swift
dependencies: [
    .package(path: "../Domain"),
    .package(path: "../FTData"),  // 추가
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.9.0")
],
targets: [
    .target(
        name: "FTFeatures",
        dependencies: [
            "Domain",
            "FTData",  // 추가
            .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
        ],
        ...
    ),
]
```

---

### 3. public 접근 제어자 누락

**문제:**
Swift Package로 분리하면 기본 접근 제어자가 `internal`이 되어 외부 모듈(메인 앱)에서 타입에 접근할 수 없습니다.

```swift
// 메인 앱에서 에러 발생
// 'RootFeature' is not accessible from this context
let store = Store(initialState: RootFeature.State()) {
    RootFeature()
}
```

**해결:**
외부에서 사용해야 하는 모든 타입, 프로퍼티, 메서드에 `public` 추가

#### RootFeature.swift
```swift
// Before
@Reducer
struct RootFeature {
    struct State: Equatable { ... }
    enum Action { ... }
    var body: some Reducer<State, Action> { ... }
}

// After
@Reducer
public struct RootFeature {
    public struct State: Equatable {
        public var appState: AppState = .loading
        public var mainTab: MainTabFeature.State?
        public var currentUser: User?

        public enum AppState: Equatable { ... }
        public init(...) { ... }
    }
    public enum Action: Sendable { ... }
    public struct RootData: Equatable, Sendable { ... }
    public init() {}
    public var body: some Reducer<State, Action> { ... }
}
```

#### MainTabFeature.swift
```swift
// Before
@Reducer
struct MainTabFeature { ... }

// After
@Reducer
public struct MainTabFeature {
    public struct State: Equatable {
        public var selectedTab: Tab = .home
        public var home: HomeFeature.State
        public enum Tab: Hashable, Sendable { ... }
        public init(...) { ... }
    }
    public enum Action: Sendable { ... }
    public init() {}
    public var body: some Reducer<State, Action> { ... }
}
```

#### HomeFeature.swift
```swift
// Before
@Reducer
struct HomeFeature { ... }

// After
@Reducer
public struct HomeFeature {
    public struct State: Equatable {
        public var todayQuestion: Question?
        public var familyTree: FamilyTree = FamilyTree()
        // ... 모든 프로퍼티 public
        public init(...) { ... }
    }
    public enum Action: Sendable { ... }
    public init() {}
    public var body: some Reducer<State, Action> { ... }
}
```

#### LoginFeature.swift
```swift
// Before
enum SocialProviderType { ... }
@Reducer
struct LoginFeature { ... }

// After
public enum SocialProviderType: String, CaseIterable, Equatable, Sendable {
    case kakao, naver, google
    public var displayName: String { ... }
}

@Reducer
public struct LoginFeature {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Sendable { ... }
    public init() {}
    public var body: some Reducer<State, Action> { ... }
}
```

#### DesignSystem.swift
```swift
// Before
enum FTColor { static let primary = ... }
enum FTFont { static func heading1() -> Font { ... } }
enum FTSpacing { static let xs: CGFloat = 8 }
enum FTRadius { static let small: CGFloat = 8 }

// After
public enum FTColor { public static let primary = ... }
public enum FTFont { public static func heading1() -> Font { ... } }
public enum FTSpacing { public static let xs: CGFloat = 8 }
public enum FTRadius { public static let small: CGFloat = 8 }
```

---

### 4. public init 누락

**문제:**
Swift에서 struct의 memberwise initializer는 자동으로 `internal` 접근 수준을 가집니다. 따라서 외부 모듈에서 초기화할 수 없습니다.

```swift
// 메인 앱에서 에러 발생
RootView(store: store)  // 'init(store:)' is inaccessible
```

**해결:**
모든 public struct에 명시적인 public init 추가

```swift
// RootView.swift
public struct RootView: View {
    @Bindable var store: StoreOf<RootFeature>

    // public init 추가
    public init(store: StoreOf<RootFeature>) {
        self.store = store
    }

    public var body: some View { ... }
}
```

---

### 5. Re-export 누락

**문제:**
메인 앱에서 FTFeatures만 import하면 Domain이나 ComposableArchitecture 타입을 사용할 수 없어 별도로 import해야 했습니다.

**해결:**
```swift
// FTFeatures/Sources/FTFeatures/FTFeatures.swift
@_exported import Domain
@_exported import ComposableArchitecture
```

이제 메인 앱에서 `import FTFeatures`만 하면 Domain과 TCA도 함께 사용 가능합니다.

---

### 6. @Bindable 타입 충돌 (iOS 버전 관련)

**문제:**
iOS 17 미만에서는 TCA의 `@Perception.Bindable`을 사용해야 하고, iOS 17+에서는 SwiftUI의 `@Bindable`을 사용해야 합니다. 이를 잘못 사용하면 에러가 발생합니다.

```
// iOS 17+에서 @Perception.Bindable 사용 시 에러
error: setter for 'store' is unavailable in iOS:
Use @Bindable without the 'Perception.' prefix.
```

```
// iOS 17 미만에서 @Bindable 사용 시 에러
error: 'Bindable' is ambiguous for type lookup in this context
```

**해결:**

| iOS 버전 | 사용해야 할 속성 |
|---------|----------------|
| iOS 17+ | `@Bindable` (SwiftUI) |
| iOS 15-16 | `@Perception.Bindable` (TCA) |

```swift
// iOS 17+ 타겟일 경우
import SwiftUI
import ComposableArchitecture

struct MainTabView: View {
    @Bindable var store: StoreOf<MainTabFeature>  // SwiftUI @Bindable 사용
    ...
}
```

---

## 최종 수정 파일 목록

| 파일 | 수정 내용 |
|------|----------|
| `FTFeatures/Package.swift` | Swift 5.9, iOS 17, FTData 의존성 추가 |
| `FTFeatures.swift` | `@_exported import` 추가 |
| `RootFeature.swift` | public 접근 제어자, public init 추가 |
| `RootView.swift` | public init 추가 |
| `MainTabFeature.swift` | public 접근 제어자, public init 추가 |
| `MainTabView.swift` | @Bindable 수정 |
| `HomeFeature.swift` | public 접근 제어자, public init 추가 |
| `LoginFeature.swift` | public 접근 제어자, public init 추가 |
| `DesignSystem.swift` | 모든 타입/프로퍼티 public 처리 |

---

## 모듈 분리 시 체크리스트

Swift Package로 모듈을 분리할 때 확인해야 할 사항:

- [ ] Package.swift의 Swift tools 버전이 다른 패키지와 호환되는가?
- [ ] platforms 설정이 사용하는 API와 호환되는가? (예: NavigationStack은 iOS 16+)
- [ ] 필요한 모든 의존성이 dependencies에 추가되었는가?
- [ ] 외부에서 접근해야 하는 모든 타입에 `public`이 붙어있는가?
- [ ] 모든 public struct에 `public init`이 정의되어 있는가?
- [ ] 자주 사용하는 의존성에 `@_exported import`가 적용되었는가?
- [ ] iOS 버전에 맞는 @Bindable 어트리뷰트를 사용하고 있는가?

---

## 결론

모듈 분리의 핵심은 **접근 제어자(Access Control)** 관리입니다. Swift Package로 분리하면 기본 접근 수준이 `internal`이 되므로, 외부에서 사용할 모든 API에 명시적으로 `public`을 추가해야 합니다.


⏺ @_exported import (Re-export)

  Re-export는 모듈 A가 import한 모듈 B를 다시 외부로 노출시키는 것입니다.

  // FTFeatures 모듈
  @_exported import Domain
  @_exported import ComposableArchitecture

  효과:
  // 메인 앱 - re-export 없이
  import FTFeatures
  import Domain                    // 별도로 import 필요
  import ComposableArchitecture    // 별도로 import 필요

  // 메인 앱 - re-export 사용 시
  import FTFeatures  // 이것만으로 Domain, TCA 타입 모두 사용 가능

  @_exported는 언더스코어로 시작하는 비공식 API이지만, 널리 사용됩니다.

  ---
  Perception

  Perception은 TCA(The Composable Architecture)에서 제공하는 라이브러리로, iOS 17 미만에서 @Observable 매크로와 유사한 기능을 제공합니다.

  배경

  | iOS 버전  | 상태 관찰 방식                                |
  |-----------|-----------------------------------------------|
  | iOS 17+   | SwiftUI @Observable, @Bindable                |
  | iOS 13-16 | ObservableObject, @Published, @ObservedObject |

  TCA는 iOS 17의 @Observable 패턴을 iOS 15-16에서도 사용할 수 있도록 Perception 라이브러리를 만들었습니다.

  사용 예시

  // iOS 17+ (SwiftUI 네이티브)
  import SwiftUI

  struct MyView: View {
      @Bindable var store: StoreOf<MyFeature>  // SwiftUI.Bindable
  }

  // iOS 15-16 (Perception 사용)
  import SwiftUI
  import Perception

  struct MyView: View {
      @Perception.Bindable var store: StoreOf<MyFeature>  // Perception.Bindable
  }

  왜 충돌이 발생하나?

  iOS 17+에서 @Bindable을 사용하면:
  - SwiftUI.Bindable
  - Perception.Bindable (TCA가 re-export)

  두 타입이 동시에 존재해서 ambiguous 에러가 발생합니다.

  해결: iOS 17+ 타겟이면 SwiftUI의 @Bindable만 사용하면 됩니다.
