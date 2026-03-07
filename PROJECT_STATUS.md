# FamTree 프로젝트 현황

> 최종 업데이트: 2026-01-21

## 프로젝트 개요

가족 구성원들이 매일의 질문에 답하며 함께 성장하는 소통 앱. 나무 성장 메타포를 통해 가족의 유대감을 시각적으로 표현합니다.

### 기술 스택
- **아키텍처**: Clean Architecture + TCA (The Composable Architecture)
- **프레임워크**: SwiftUI, Swift 5.9+
- **최소 지원**: iOS 17+ (FTFeatures), iOS 15+ (Domain/FTData)
- **모듈 구성**: Domain → FTData → FTFeatures → FamTree (main app)
- **패키지 관리**: SPM (Swift Package Manager)
- **TCA 버전**: 1.9.0+

---

## 전체 진행률

| 레이어 | 상태 | 진행률 |
|--------|------|--------|
| Domain | 완료 | 90% |
| FTData (API/Repository) | 대부분 완료 | 70% |
| FTFeatures (UI/Feature) | 대부분 완료 | 90% |
| API 연동 | Mock 데이터 사용 중 | 10% |
| 테스트 | 미착수 | 0% |
| **전체** | | **~85%** |

---

## 아키텍처 구조

```
┌─────────────────────────────────────────────────────────────┐
│                    FamTree (Main App)                       │
│                    FamTreeApp.swift                         │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                   FTFeatures (UI/TCA)                       │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │  Root   │ │  Home   │ │  Tree   │ │ Family  │ ...       │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘           │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    FTData (Data Layer)                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ APIClient   │  │ Repositories │  │    DTOs     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                   Domain (Business Logic)                   │
│  ┌─────────────┐  ┌─────────────────────────┐              │
│  │  Entities   │  │  Repository Interfaces  │              │
│  └─────────────┘  └─────────────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

---

## 구현 완료 항목

### Domain Layer (90%)

**Entities (8개)**
| Entity | 설명 | 상태 |
|--------|------|------|
| User | 사용자 프로필, 가족 역할 | ✅ |
| Family | 가족 그룹 컨테이너 | ✅ |
| Member | 가족 멤버십 정보 | ✅ |
| Question | 질문 템플릿 (5개 카테고리) | ✅ |
| DailyQuestion | 오늘의 질문 인스턴스 | ✅ |
| Answer | 사용자 답변 | ✅ |
| TreeProgress | 나무 성장 상태 (6단계) | ✅ |
| Notification | 알림 정보 | ✅ |

**Repository Interfaces (7개)**
- `AuthRepositoryInterface` - 로그인, 회원가입, 로그아웃, getCurrentUser
- `UserRepositoryInterface` - 사용자 CRUD
- `FamilyRepositoryInterface` - 가족 관리
- `QuestionRepositoryInterface` - 질문 조회
- `DailyQuestionRepositoryInterface` - 일일 질문 로직
- `AnswerRepositoryInterface` - 답변 관리
- `TreeRepositoryInterface` - 나무 성장 추적

---

### FTData Layer (70%)

**API Client**
| 컴포넌트 | 설명 | 상태 |
|----------|------|------|
| APIClient | HTTP 요청 처리 (URLSession) | ✅ |
| APIEndpoint | 엔드포인트 프로토콜 | ✅ |
| APIError | 에러 처리 | ✅ |
| AuthEndpoint | 인증 API | ✅ |
| UserEndpoint | 사용자 API | ✅ |
| FamilyEndpoint | 가족 API | ✅ |
| QuestionEndpoint | 질문 API | ✅ |
| DailyQuestionEndpoint | 일일 질문 API | ✅ |
| AnswerEndpoint | 답변 API | ✅ |

**로컬 저장소**
- TokenStorage - JWT 토큰 저장
- UserLocalDataSource - 사용자 정보 캐싱
- AuthLocalDataSource - 인증 상태 관리

**Repository 구현** - 7개 모두 구현 완료

**DTOs** - UserDTO, FamilyDTO, QuestionDTO, AnswerDTO, TreeProgressDTO, DailyQuestionDTO, MemberDTO

---

### FTFeatures Layer (90%)

**구현된 Features (13개)**

| Feature | 설명 | 상태 |
|---------|------|------|
| RootFeature | 앱 초기화, 인증 상태 관리, 네비게이션 | ✅ |
| MainTabFeature | 4개 탭 네비게이션 | ✅ |
| HomeFeature | 오늘의 질문, 고슴도치 정원 | ✅ |
| LoginFeature | 이메일/소셜 로그인 선택 | ✅ |
| CreateFamilyFeature | 새 가족 그룹 생성 | ✅ |
| JoinFamilyFeature | 초대 코드로 가족 참여 | ✅ |
| QuestionDetailFeature | 질문 상세, 답변 입력, 가족 답변 | ✅ |
| TreeFeature | 나무 성장 시각화 (6단계) | ✅ |
| FamilyFeature | 가족 정보, 구성원, 초대 코드 | ✅ |
| SettingsFeature | 설정, 로그아웃 | ✅ |
| HistoryFeature | 달력 기반 과거 질문 | ✅ |
| NotificationFeature | 알림 목록, 읽음/삭제 | ✅ |
| ProfileEditFeature | 프로필 수정 | ✅ |

**구현된 Views**
- RootView, MainTabView
- HomeView, HedgehogView, HedgehogGardenView
- LoginView, EmailLoginView
- CreateFamilyView, JoinFamilyView, FamilyTabView
- QuestionDetailView
- TreeTabView, AnimatedTreeView
- SettingsTabView
- HistoryView (달력 UI)
- NotificationView
- ProfileEditView

**공통 컴포넌트**
- FTButton - 스타일 버튼, 로딩 상태
- FTTextField - 커스텀 텍스트 입력
- FTCard - 카드 컨테이너
- FTLogo - 브랜드 로고

**DesignSystem**
- 색상 팔레트 (Primary: #4CAF50 녹색 계열)
- 타이포그래피 (7가지 폰트 스케일)
- 스페이싱 (xs, sm, md, lg, xl)
- 라디우스 (표준화된 모서리 값)

---

## 핵심 기능 구현 현황

### 질문 시스템
| 기능 | 설명 | 상태 |
|------|------|------|
| 5가지 카테고리 | 일상, 추억, 가치관, 미래, 감사 | ✅ |
| 일일 질문 배달 | 고정 시간 배달 | ✅ 구조 |
| 카테고리별 조회 | 카테고리 필터링 | ✅ |
| 순서 기반 진행 | 질문 순서 추적 | ✅ |

### 나무 성장 시스템
| 단계 | 설명 | 상태 |
|------|------|------|
| Seed | 씨앗 | ✅ |
| Sprout | 새싹 | ✅ |
| Sapling | 묘목 | ✅ |
| YoungTree | 어린 나무 | ✅ |
| MatureTree | 성숙한 나무 | ✅ |
| Flowering | 꽃피는 나무 | ✅ |
| 애니메이션 | 단계별 전환 애니메이션 | ✅ |

### 가족 관리
| 기능 | 설명 | 상태 |
|------|------|------|
| 가족 생성 | 새 가족 그룹 생성 | ✅ |
| 초대 코드 | 코드 기반 참여 | ✅ |
| 역할 시스템 | 아버지, 어머니, 아들, 딸, 할아버지, 할머니 | ✅ |
| 구성원 목록 | 가족 멤버 표시 | ✅ |

### 고슴도치 정원
| 기능 | 설명 | 상태 |
|------|------|------|
| 캐릭터 표시 | 가족 구성원당 1마리 | ✅ |
| 이동 애니메이션 | 자연스러운 움직임 | ✅ |
| 상태 반영 | 답변 여부 시각화 | ✅ |

---

## 해야 할 작업

### P0 - 긴급 (MVP 필수)

| 작업 | 설명 | 우선순위 | 예상 난이도 |
|------|------|----------|-------------|
| API 서버 연동 | Mock → 실제 서버 전환 | 최상 | 높음 |
| 이메일 인증 구현 | 실제 로그인/회원가입 | 최상 | 중간 |
| Error Handling 고도화 | 네트워크/유효성 에러 UI | 높음 | 중간 |
| 로딩 상태 UI | 전역 로딩 인디케이터 | 높음 | 낮음 |

### P1 - 중요

| 작업 | 설명 | 우선순위 | 예상 난이도 |
|------|------|----------|-------------|
| Unit 테스트 작성 | Feature별 테스트 | 높음 | 중간 |
| Integration 테스트 | E2E 시나리오 | 높음 | 높음 |
| Push Notification | APNs 연동 | 높음 | 높음 |
| 오프라인 지원 | 로컬 캐싱 강화 | 중간 | 중간 |

### P2 - 추가 기능

| 작업 | 설명 | 우선순위 | 예상 난이도 |
|------|------|----------|-------------|
| 소셜 로그인 | Apple/Google/Kakao | 중간 | 높음 |
| 사진 첨부 | 답변에 이미지 추가 | 중간 | 중간 |
| 반응/댓글 | 답변에 반응 달기 | 중간 | 중간 |
| 통계/인사이트 | 가족 활동 대시보드 | 낮음 | 중간 |
| 배지 시스템 | 활동 보상 배지 | 낮음 | 낮음 |
| 다중 가족 지원 | 여러 가족 그룹 | 낮음 | 높음 |

### P3 - 향후 고려

| 작업 | 설명 |
|------|------|
| 위젯 | iOS 홈 화면 위젯 |
| Watch 앱 | Apple Watch 지원 |
| 다국어 지원 | 영어/일본어 등 |
| 접근성 개선 | VoiceOver 최적화 |
| 다크 모드 | 테마 지원 |

---

## 프로젝트 구조

```
/Users/yong/Desktop/FamTree/
├── Domain/                          # 비즈니스 로직 레이어
│   ├── Package.swift
│   ├── Sources/Domain/
│   │   ├── Entities/                # 8개 Entity
│   │   └── Repositories/            # 7개 Protocol
│   └── Tests/DomainTests/
│
├── FTData/                          # 데이터 레이어
│   ├── Package.swift
│   ├── Sources/FTData/
│   │   ├── DataSources/
│   │   │   ├── Remote/API/          # APIClient, Endpoints
│   │   │   │   └── Services/        # API 서비스들
│   │   │   └── Local/               # 로컬 저장소
│   │   ├── Repositories/            # 7개 구현체
│   │   ├── DTOs/                    # 데이터 전송 객체
│   │   └── Mappers/                 # DTO ↔ Entity 변환
│
├── FTFeatures/                      # 프레젠테이션 레이어 (TCA)
│   ├── Package.swift
│   ├── Sources/FTFeatures/
│   │   ├── Presentation/
│   │   │   ├── Root/                # RootFeature, RootView
│   │   │   ├── MainTab/             # MainTabFeature, MainTabView
│   │   │   ├── Home/                # HomeFeature, HedgehogView
│   │   │   ├── Login/               # LoginFeature, EmailLoginView
│   │   │   ├── Family/              # Create/Join/FamilyFeature
│   │   │   ├── Question/            # QuestionDetailFeature
│   │   │   ├── Tree/                # TreeFeature, AnimatedTreeView
│   │   │   ├── Settings/            # SettingsFeature
│   │   │   ├── History/             # HistoryFeature (달력)
│   │   │   ├── Notification/        # NotificationFeature
│   │   │   ├── Profile/             # ProfileEditFeature
│   │   │   └── Common/              # 공통 컴포넌트
│   │   └── Design/                  # DesignSystem.swift
│
├── FamTree/                         # 메인 iOS 앱
│   ├── FamTreeApp.swift             # 앱 진입점
│   └── Assets.xcassets/             # 이미지, 아이콘
│
├── Documents/                       # 문서
│   ├── PRD_FamilyTree.md           # 제품 요구사항
│   ├── PROJECT_STRUCTURE.md         # 아키텍처 가이드
│   └── DEVELOPMENT_ROADMAP.md       # 개발 로드맵
│
├── FTFeatures_Fix.md               # 모듈 분리 이슈 해결
└── PROJECT_STATUS.md               # 현재 문서
```

---

## API 엔드포인트 구조

**Base URL**: `https://api.familytree.com/v1`

| 경로 | 설명 |
|------|------|
| `/auth/*` | 인증 (login, signup, logout, refresh) |
| `/users/*` | 사용자 관리 |
| `/families/*` | 가족 그룹 관리 |
| `/questions/*` | 질문 조회 |
| `/daily-questions/*` | 일일 질문 |
| `/answers/*` | 답변 관리 |
| `/members/*` | 가족 구성원 |

---

## 해결된 이슈

1. ✅ Swift/iOS 버전 불일치 → Swift 5.9, iOS 17로 통일
2. ✅ FTData 의존성 누락 → Package.swift에 추가
3. ✅ public 접근 제어자 누락 → 외부 API에 모두 public 추가
4. ✅ public init 누락 → 모든 public struct에 명시적 initializer 추가
5. ✅ Re-export 구성 → @_exported import 적용
6. ✅ @Bindable 타입 충돌 → iOS 버전별 올바른 사용법 적용

---

## 권장 작업 순서

```
✅ 완료된 작업
├── Domain Layer 구현
├── FTData Layer 구현
├── 13개 Features 구현
├── 모든 Views 구현
├── DesignSystem 구현
└── P2 기능 (History, Notification, ProfileEdit)

⏳ 다음 단계
├── 1. API 서버 구축/연동
│   ├── 백엔드 서버 개발 (or Firebase/Supabase)
│   ├── Mock → 실제 API 전환
│   └── 인증 플로우 완성
│
├── 2. Error Handling 개선
│   ├── 네트워크 에러 UI
│   ├── 유효성 검사 피드백
│   └── 재시도 로직
│
├── 3. 테스트 코드 작성
│   ├── TCA Reducer 테스트
│   ├── Repository 테스트
│   └── Integration 테스트
│
├── 4. Push Notification
│   ├── APNs 설정
│   ├── 서버 연동
│   └── 알림 스케줄링
│
└── 5. 출시 준비
    ├── 앱 아이콘/스크린샷
    ├── App Store 메타데이터
    └── 베타 테스트 (TestFlight)
```

---

## 빌드 상태

| 항목 | 상태 |
|------|------|
| 모듈 분리 | ✅ 완료 |
| 컴파일 | ✅ 성공 |
| Mock 데이터 구동 | ✅ 가능 |
| API 연동 | ⏳ 대기 |
| 테스트 | ❌ 미작성 |

---

## Git 최근 커밋

| 커밋 | 내용 |
|------|------|
| `29969dd` | 홈 화면 수정 + 이미지 애니메이션 |
| `345d461` | 로그인 화면 업데이트 + 이메일 로그인 UI |
| `49eb16f` | 디자인 시스템 리팩토링 |
| `c159240` | 에셋 추가 (아이콘, 이미지) |
| `e79323b` | 앱 구조 리팩토링 |

---

## 참고 문서

- `Documents/PRD_FamilyTree.md` - 제품 요구사항 정의서
- `Documents/PROJECT_STRUCTURE.md` - 아키텍처 상세 가이드
- `Documents/DEVELOPMENT_ROADMAP.md` - 개발 로드맵
- `FTFeatures_Fix.md` - 모듈 분리 시 해결한 이슈

---

## 연락처 및 리소스

- **디자인**: Figma (별도 링크 필요)
- **백엔드 API**: 미정 (구축 필요)
- **이슈 트래킹**: GitHub Issues (설정 권장)
