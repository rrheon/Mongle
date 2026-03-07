# FamilyTree 프로젝트 구조

## 개요
FamilyTree는 Clean Architecture와 TCA(The Composable Architecture)를 기반으로 한 SwiftUI 앱입니다.

---

## 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                  Presentation Layer                      │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Features (TCA)                                   │   │
│  │  - State, Action, Reducer                        │   │
│  │  - Views (SwiftUI)                               │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                    Domain Layer                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Entities                                         │   │
│  │  - User, Family, Question, Answer, Tree          │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │  UseCases                                         │   │
│  │  - Business Logic                                 │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Repository Interfaces                            │   │
│  │  - Protocols                                      │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                     Data Layer                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Repository Implementations                       │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Data Sources                                     │   │
│  │  - Remote (API)                                   │   │
│  │  - Local (SwiftData/Core Data)                   │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │  DTOs & Mappers                                   │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 폴더 구조

```
AnonymousMessageApp/
├── Domain/
│   ├── Entities/
│   │   ├── User.swift
│   │   ├── Family.swift
│   │   ├── Member.swift
│   │   ├── Question.swift
│   │   ├── DailyQuestion.swift
│   │   ├── Answer.swift
│   │   ├── Reaction.swift
│   │   ├── Comment.swift
│   │   ├── TreeProgress.swift
│   │   ├── Badge.swift
│   │   └── Notification.swift
│   │
│   ├── UseCases/
│   │   ├── Auth/
│   │   │   ├── LoginUseCase.swift
│   │   │   ├── SignupUseCase.swift
│   │   │   └── LogoutUseCase.swift
│   │   ├── Family/
│   │   │   ├── CreateFamilyUseCase.swift
│   │   │   ├── JoinFamilyUseCase.swift
│   │   │   └── GetFamilyMembersUseCase.swift
│   │   ├── Question/
│   │   │   ├── GetTodayQuestionUseCase.swift
│   │   │   └── GetQuestionHistoryUseCase.swift
│   │   ├── Answer/
│   │   │   ├── CreateAnswerUseCase.swift
│   │   │   ├── GetAnswersUseCase.swift
│   │   │   └── RequestAnswerUseCase.swift
│   │   └── Tree/
│   │       └── GetTreeProgressUseCase.swift
│   │
│   └── RepositoryInterfaces/
│       ├── AuthRepositoryInterface.swift
│       ├── UserRepositoryInterface.swift
│       ├── FamilyRepositoryInterface.swift
│       ├── QuestionRepositoryInterface.swift
│       ├── DailyQuestionRepositoryInterface.swift
│       ├── AnswerRepositoryInterface.swift
│       └── TreeRepositoryInterface.swift
│
├── Data/
│   ├── Repositories/
│   │   ├── AuthRepository.swift
│   │   ├── UserRepository.swift
│   │   ├── FamilyRepository.swift
│   │   ├── QuestionRepository.swift
│   │   ├── DailyQuestionRepository.swift
│   │   ├── AnswerRepository.swift
│   │   └── TreeRepository.swift
│   │
│   ├── DataSources/
│   │   ├── Remote/
│   │   │   ├── Services/
│   │   │   │   ├── AuthAPIService.swift
│   │   │   │   ├── FamilyAPIService.swift
│   │   │   │   ├── QuestionAPIService.swift
│   │   │   │   ├── AnswerAPIService.swift
│   │   │   │   └── TreeAPIService.swift
│   │   │   └── NetworkClient.swift
│   │   │
│   │   └── Local/
│   │       ├── CoreData/
│   │       │   └── FamilyTreeModel.xcdatamodeld
│   │       └── SwiftData/
│   │           └── Models/
│   │
│   ├── DTOs/
│   │   ├── UserDTO.swift
│   │   ├── FamilyDTO.swift
│   │   ├── QuestionDTO.swift
│   │   ├── DailyQuestionDTO.swift
│   │   ├── AnswerDTO.swift
│   │   └── TreeProgressDTO.swift
│   │
│   └── Mappers/
│       ├── UserMapper.swift
│       ├── FamilyMapper.swift
│       ├── QuestionMapper.swift
│       ├── DailyQuestionMapper.swift
│       ├── AnswerMapper.swift
│       └── TreeProgressMapper.swift
│
├── Presentation/
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── Login/
│   │   │   │   ├── LoginFeature.swift
│   │   │   │   └── LoginView.swift
│   │   │   └── Signup/
│   │   │       ├── SignupFeature.swift
│   │   │       └── SignupView.swift
│   │   │
│   │   ├── Onboarding/
│   │   │   ├── CreateFamily/
│   │   │   │   ├── CreateFamilyFeature.swift
│   │   │   │   └── CreateFamilyView.swift
│   │   │   └── JoinFamily/
│   │   │       ├── JoinFamilyFeature.swift
│   │   │       └── JoinFamilyView.swift
│   │   │
│   │   ├── Home/
│   │   │   ├── HomeFeature.swift
│   │   │   ├── HomeView.swift
│   │   │   └── Components/
│   │   │       ├── TreeVisualizationView.swift
│   │   │       ├── TodayQuestionCard.swift
│   │   │       └── MemberStatusView.swift
│   │   │
│   │   ├── Question/
│   │   │   ├── QuestionDetail/
│   │   │   │   ├── QuestionDetailFeature.swift
│   │   │   │   └── QuestionDetailView.swift
│   │   │   └── AnswerInput/
│   │   │       ├── AnswerInputFeature.swift
│   │   │       └── AnswerInputView.swift
│   │   │
│   │   ├── AnswerList/
│   │   │   ├── AnswerListFeature.swift
│   │   │   ├── AnswerListView.swift
│   │   │   └── Components/
│   │   │       ├── AnswerCard.swift
│   │   │       ├── ReactionButton.swift
│   │   │       └── CommentSection.swift
│   │   │
│   │   ├── History/
│   │   │   ├── HistoryFeature.swift
│   │   │   ├── HistoryView.swift
│   │   │   └── Components/
│   │   │       └── CalendarView.swift
│   │   │
│   │   ├── Tree/
│   │   │   ├── TreeFeature.swift
│   │   │   ├── TreeView.swift
│   │   │   └── Components/
│   │   │       ├── TreeStageView.swift
│   │   │       ├── ProgressBar.swift
│   │   │       └── BadgeList.swift
│   │   │
│   │   └── Family/
│   │       ├── FamilyFeature.swift
│   │       ├── FamilyView.swift
│   │       └── Components/
│   │           ├── MemberCard.swift
│   │           └── InviteCodeView.swift
│   │
│   └── Common/
│       ├── Components/
│       │   ├── CustomButton.swift
│       │   ├── CustomTextField.swift
│       │   ├── LoadingView.swift
│       │   └── ErrorView.swift
│       └── Extensions/
│           ├── Color+Theme.swift
│           ├── Font+Custom.swift
│           └── View+Extensions.swift
│
├── Core/
│   ├── DependencyInjection/
│   │   ├── RepositoryDependencies.swift
│   │   ├── UseCaseDependencies.swift
│   │   └── Container.swift
│   │
│   ├── Network/
│   │   ├── NetworkError.swift
│   │   ├── HTTPMethod.swift
│   │   └── Endpoint.swift
│   │
│   └── Utils/
│       ├── DateFormatter+Custom.swift
│       ├── Validation.swift
│       └── Constants.swift
│
├── Resources/
│   ├── Assets.xcassets/
│   │   ├── Colors/
│   │   ├── Images/
│   │   └── Icons/
│   └── Fonts/
│
└── FamilyTreeApp.swift
```

---

## 주요 컴포넌트 설명

### 1. Domain Layer
- **Entities**: 비즈니스 도메인의 핵심 객체
- **UseCases**: 비즈니스 로직을 캡슐화한 유즈케이스
- **Repository Interfaces**: 데이터 접근 계층의 추상화

### 2. Data Layer
- **Repositories**: Repository 인터페이스의 구현체
- **DataSources**: 실제 데이터 소스 (API, 로컬 DB)
- **DTOs**: 데이터 전송 객체
- **Mappers**: DTO ↔ Entity 변환

### 3. Presentation Layer
- **Features**: TCA 기반의 Feature 단위 모듈
  - State: 화면 상태
  - Action: 사용자 액션 및 이벤트
  - Reducer: State 변환 로직
- **Views**: SwiftUI 뷰
- **Components**: 재사용 가능한 UI 컴포넌트

### 4. Core
- **DependencyInjection**: 의존성 주입 컨테이너
- **Network**: 네트워크 관련 유틸리티
- **Utils**: 공통 유틸리티

---

## TCA Feature 구조 예시

```swift
// HomeFeature.swift
struct HomeFeature: Reducer {
    struct State: Equatable {
        var family: Family?
        var todayQuestion: Question?
        var dailyQuestion: DailyQuestion?
        var treeProgress: TreeProgress?
        var members: [Member] = []
        var answerStatus: [UUID: Bool] = [:]
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case onAppear
        case fetchTodayQuestion
        case fetchTreeProgress
        case fetchMembers
        case todayQuestionResponse(Result<(Question, DailyQuestion), Error>)
        case treeProgressResponse(Result<TreeProgress, Error>)
        case membersResponse(Result<[Member], Error>)
        case navigateToAnswer
        case navigateToAnswerList
        case navigateToTree
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            // 초기 데이터 로딩
        case .fetchTodayQuestion:
            // 오늘의 질문 조회
        // ...
        }
    }
}
```

---

## 데이터 흐름

### 1. 사용자 액션 → State 변경
```
User Interaction
    ↓
View sends Action to Store
    ↓
Reducer processes Action
    ↓
UseCase execution (Business Logic)
    ↓
Repository call (Data Access)
    ↓
State updated
    ↓
View re-renders
```

### 2. 예시: 답변 생성 흐름
```
1. User taps "답변 제출" button
2. AnswerInputView sends .submitButtonTapped action
3. AnswerInputFeature.Reducer processes action
4. CreateAnswerUseCase.execute() is called
5. AnswerRepository.create() saves answer to backend
6. DailyQuestionRepository.update() updates completion status
7. TreeRepository.update() updates tree progress (if all answered)
8. State is updated with new answer and tree progress
9. View re-renders showing updated state
10. Navigation to AnswerListView (if completed)
```

---

## 의존성 주입

### Dependencies.swift 예시
```swift
import ComposableArchitecture

// Repository Dependencies
extension DependencyValues {
    var familyRepository: FamilyRepositoryInterface {
        get { self[FamilyRepositoryKey.self] }
        set { self[FamilyRepositoryKey.self] = newValue }
    }
}

private enum FamilyRepositoryKey: DependencyKey {
    static let liveValue: FamilyRepositoryInterface = FamilyRepository()
}

// UseCase Dependencies
extension DependencyValues {
    var createFamilyUseCase: CreateFamilyUseCase {
        get { self[CreateFamilyUseCaseKey.self] }
        set { self[CreateFamilyUseCaseKey.self] = newValue }
    }
}

private enum CreateFamilyUseCaseKey: DependencyKey {
    static let liveValue = CreateFamilyUseCase(
        familyRepository: FamilyRepository(),
        treeRepository: TreeRepository()
    )
}
```

---

## 테스트 전략

### 1. Unit Tests
- **Domain Layer**
  - UseCases 테스트 (Mock Repository 사용)
  - Entities 비즈니스 로직 테스트

### 2. Integration Tests
- **Data Layer**
  - Repository 구현 테스트
  - Mapper 테스트

### 3. UI Tests
- **Presentation Layer**
  - TCA Feature 테스트 (TestStore 사용)
  - Snapshot 테스트

---

## 빌드 설정

### Minimum Deployment Target
- iOS 16.0+

### Frameworks & Libraries
- SwiftUI
- TCA (The Composable Architecture)
- SwiftData or Core Data
- Combine

### Package Dependencies (SPM)
```swift
dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
]
```

---

## Git 브랜치 전략

### Main Branches
- `main`: 프로덕션 릴리즈
- `develop`: 개발 통합 브랜치

### Feature Branches
- `feature/auth`: 인증 기능
- `feature/family`: 가족 그룹 기능
- `feature/question`: 질문 기능
- `feature/answer`: 답변 기능
- `feature/tree`: 나무 성장 기능

### 브랜치 규칙
- Feature 브랜치는 `develop`에서 분기
- PR은 `develop`으로 머지
- `develop`이 안정화되면 `main`으로 머지

---

## 다음 단계

1. ✅ PRD 작성
2. ✅ Domain Layer 구현 (Entities, UseCases, Repository Interfaces)
3. ⬜ Data Layer 구현 (Repositories, DataSources, DTOs, Mappers)
4. ⬜ Presentation Layer 구현 (Features, Views)
5. ⬜ 테스트 작성
6. ⬜ CI/CD 설정
7. ⬜ 배포

---

**작성일**: 2025-12-08
**버전**: 1.0.0
