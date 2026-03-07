# FamilyTree 개발 로드맵

## 개요
FamilyTree 앱의 단계별 개발 계획 및 우선순위를 정의합니다.

---

## Phase 1: MVP (Minimum Viable Product) - 4-6주

### 목표
핵심 기능으로 사용 가능한 첫 버전 출시

### 주요 기능
1. **인증 시스템** (1주)
2. **가족 그룹 & 구성원 관리** (1주)
3. **질문-답변 시스템** (2주)
4. **기본 나무 시각화** (1주)
5. **기본 알림** (1주)

---

## Phase 1 상세 일정

### Week 1: 인증 & 기본 설정

#### Day 1-2: 프로젝트 설정
- [x] PRD 작성
- [x] Domain Layer 설계 (Entities, UseCases, Repository Interfaces)
- [ ] Xcode 프로젝트 설정
- [ ] TCA, Dependencies 패키지 추가
- [ ] 폴더 구조 생성
- [ ] Git 설정 및 `.gitignore` 작성

#### Day 3-5: 인증 기능
**Domain Layer:**
- [ ] LoginUseCase 구현 ✅ (이미 작성됨)
- [ ] SignupUseCase 구현
- [ ] LogoutUseCase 구현

**Data Layer:**
- [ ] AuthRepository 구현
- [ ] AuthAPIService 구현 (Mock 또는 실제 API)
- [ ] UserRepository 구현
- [ ] UserDTO, UserMapper 구현

**Presentation Layer:**
- [ ] LoginFeature 구현
- [ ] LoginView 구현
- [ ] SignupFeature 구현
- [ ] SignupView 구현
- [ ] 프로필 설정 화면

**테스트:**
- [ ] LoginUseCase 단위 테스트
- [ ] SignupUseCase 단위 테스트
- [ ] LoginFeature 테스트 (TestStore)

---

### Week 2: 가족 그룹 관리

#### Day 1-3: 가족 그룹 생성 & 참여
**Domain Layer:**
- [ ] CreateFamilyUseCase 구현 ✅ (이미 작성됨)
- [ ] JoinFamilyUseCase 구현 ✅ (이미 작성됨)
- [ ] GetFamilyMembersUseCase 구현

**Data Layer:**
- [ ] FamilyRepository 구현
- [ ] FamilyAPIService 구현
- [ ] FamilyDTO, FamilyMapper 구현
- [ ] MemberDTO, MemberMapper 구현

**Presentation Layer:**
- [ ] CreateFamilyFeature 구현
- [ ] CreateFamilyView 구현 (씨앗 심기 애니메이션)
- [ ] JoinFamilyFeature 구현
- [ ] JoinFamilyView 구현 (초대 코드 입력)

**테스트:**
- [ ] CreateFamilyUseCase 단위 테스트
- [ ] JoinFamilyUseCase 단위 테스트
- [ ] FamilyRepository 통합 테스트

#### Day 4-5: 구성원 관리
**Presentation Layer:**
- [ ] FamilyFeature 구현
- [ ] FamilyView 구현
- [ ] MemberCard 컴포넌트
- [ ] InviteCodeView 컴포넌트
- [ ] 초대 링크 공유 기능

---

### Week 3-4: 질문-답변 시스템

#### Week 3 Day 1-3: 질문 기능
**Domain Layer:**
- [ ] GetTodayQuestionUseCase 구현 ✅ (이미 작성됨)
- [ ] GetQuestionHistoryUseCase 구현

**Data Layer:**
- [ ] QuestionRepository 구현
- [ ] DailyQuestionRepository 구현
- [ ] QuestionAPIService 구현
- [ ] QuestionDTO, QuestionMapper 구현
- [ ] DailyQuestionDTO, DailyQuestionMapper 구현

**Presentation Layer:**
- [ ] QuestionDetailFeature 구현
- [ ] QuestionDetailView 구현
- [ ] TodayQuestionCard 컴포넌트

**데이터 준비:**
- [ ] 초기 질문 데이터 세트 작성 (최소 100개)
- [ ] 질문 카테고리별 분류
- [ ] 질문 순서 설정

#### Week 3 Day 4-5: 답변 작성 기능
**Domain Layer:**
- [ ] CreateAnswerUseCase 구현 ✅ (이미 작성됨)
- [ ] GetAnswersUseCase 구현 ✅ (이미 작성됨)

**Data Layer:**
- [ ] AnswerRepository 구현
- [ ] AnswerAPIService 구현
- [ ] AnswerDTO, AnswerMapper 구현

**Presentation Layer:**
- [ ] AnswerInputFeature 구현
- [ ] AnswerInputView 구현
- [ ] 텍스트 입력 필드 (최대 500자)
- [ ] 임시 저장 기능
- [ ] 답변 제출 기능

**테스트:**
- [ ] CreateAnswerUseCase 단위 테스트
- [ ] GetAnswersUseCase 단위 테스트
- [ ] AnswerRepository 통합 테스트

#### Week 4 Day 1-3: 답변 공개 & 확인 기능
**Presentation Layer:**
- [ ] AnswerListFeature 구현
- [ ] AnswerListView 구현
- [ ] AnswerCard 컴포넌트
- [ ] 구성원별 답변 카드 UI
- [ ] 답변 상태 표시 (완료/대기 중)
- [ ] 모든 구성원 답변 완료 시 공개 로직

**비즈니스 로직:**
- [ ] 답변 완료 여부 확인 로직
- [ ] 답변 잠금/공개 로직
- [ ] 구성원별 답변 상태 추적

#### Week 4 Day 4-5: 답변 요청 기능
**Domain Layer:**
- [ ] RequestAnswerUseCase 구현

**Presentation Layer:**
- [ ] 답변 요청 버튼 추가
- [ ] 미답변자 목록 표시
- [ ] 답변 요청 알림 전송

---

### Week 5: 나무 시각화 & 성장 시스템

#### Day 1-3: 나무 성장 로직
**Domain Layer:**
- [ ] GetTreeProgressUseCase 구현 ✅ (이미 작성됨)
- [ ] UpdateTreeProgressUseCase 구현

**Data Layer:**
- [ ] TreeRepository 구현
- [ ] TreeAPIService 구현
- [ ] TreeProgressDTO, TreeProgressMapper 구현

**비즈니스 로직:**
- [ ] 답변 횟수에 따른 성장 단계 계산
- [ ] 연속 답변 일수 계산 로직
- [ ] 나무 성장 업데이트 트리거

**테스트:**
- [ ] TreeProgress 계산 로직 테스트
- [ ] TreeStage 전환 테스트

#### Day 4-5: 나무 UI 구현
**Presentation Layer:**
- [ ] TreeFeature 구현
- [ ] TreeView 구현
- [ ] TreeStageView 컴포넌트 (6단계 나무 비주얼)
- [ ] ProgressBar 컴포넌트
- [ ] 성장 애니메이션
- [ ] TreeVisualizationView (홈 화면용)

**디자인:**
- [ ] 6단계 나무 이미지 에셋 준비
  - 씨앗 🌰
  - 새싹 🌱
  - 어린 나무 🌿
  - 청년 나무 🌳
  - 성목 🌲
  - 꽃 피는 나무 🌸
- [ ] 성장 애니메이션 디자인

---

### Week 6: 알림 & 홈 화면

#### Day 1-2: 푸시 알림 기본 설정
**기능:**
- [ ] APNs 설정
- [ ] 푸시 알림 권한 요청
- [ ] 알림 타입 정의

**알림 종류:**
- [ ] 새 질문 도착 알림 (매일 오전 11시)
- [ ] 모든 구성원 답변 완료 알림
- [ ] 답변 요청 알림

**Data Layer:**
- [ ] NotificationService 구현
- [ ] 로컬 알림 스케줄링

#### Day 3-5: 홈 화면 구현
**Presentation Layer:**
- [ ] HomeFeature 구현
- [ ] HomeView 구현
- [ ] 상단: 나무 비주얼
- [ ] 중앙: 오늘의 질문 카드
- [ ] 하단: 구성원 답변 상태
- [ ] 하단 탭바 (홈, 히스토리, 가족, 설정)

**통합:**
- [ ] 모든 기능 통합 테스트
- [ ] 전체 플로우 테스트
- [ ] 버그 수정

---

## Phase 1 체크리스트

### 필수 기능
- [ ] 이메일 회원가입/로그인
- [ ] 가족 그룹 생성
- [ ] 초대 코드로 가족 그룹 참여
- [ ] 매일 질문 제공
- [ ] 답변 작성
- [ ] 모든 구성원 답변 완료 시 공개
- [ ] 구성원별 답변 확인
- [ ] 기본 나무 시각화 (3단계)
- [ ] 새 질문 도착 알림
- [ ] 답변 완료 알림

### 추가 기능 (선택)
- [ ] 답변 요청 기능
- [ ] 프로필 사진 업로드
- [ ] 임시 저장 기능

---

## Phase 2: 핵심 기능 강화 - 3-4주

### Week 7-8: 반응 & 댓글 시스템

#### 반응 기능
**Domain Layer:**
- [ ] AddReactionUseCase 구현
- [ ] RemoveReactionUseCase 구현

**Data Layer:**
- [ ] ReactionRepository 구현
- [ ] ReactionDTO, ReactionMapper 구현

**Presentation Layer:**
- [ ] ReactionButton 컴포넌트
- [ ] 반응 타입 선택 UI
- [ ] 반응 목록 표시

#### 댓글 기능
**Domain Layer:**
- [ ] CreateCommentUseCase 구현
- [ ] GetCommentsUseCase 구현

**Data Layer:**
- [ ] CommentRepository 구현
- [ ] CommentDTO, CommentMapper 구현

**Presentation Layer:**
- [ ] CommentSection 컴포넌트
- [ ] 댓글 작성 UI
- [ ] 댓글 목록 표시

---

### Week 9: 나무 성장 고도화

#### 6단계 성장 시스템
- [ ] TreeStage 6단계 구현 완료 ✅
- [ ] 단계별 필요 답변 수 설정
- [ ] 성장 애니메이션 고도화
- [ ] 성장 축하 화면

#### 마일스톤 배지 시스템
**Domain Layer:**
- [ ] GetBadgesUseCase 구현
- [ ] CheckBadgeEligibilityUseCase 구현
- [ ] AwardBadgeUseCase 구현

**Data Layer:**
- [ ] BadgeRepository 구현
- [ ] BadgeDTO, BadgeMapper 구현

**Presentation Layer:**
- [ ] BadgeList 컴포넌트
- [ ] 배지 획득 애니메이션
- [ ] 배지 상세 화면

**배지 종류:**
- [ ] 첫 답변 배지
- [ ] 7일 연속 배지
- [ ] 30일 연속 배지
- [ ] 100일 달성 배지
- [ ] 완벽한 한 주 배지
- [ ] 얼리버드 배지

---

### Week 10: 과거 질문 아카이브

#### 히스토리 기능
**Domain Layer:**
- [ ] GetQuestionHistoryUseCase 구현

**Presentation Layer:**
- [ ] HistoryFeature 구현
- [ ] HistoryView 구현
- [ ] CalendarView 컴포넌트
- [ ] 날짜별 질문/답변 확인
- [ ] 검색 및 필터링

---

## Phase 3: 추가 기능 - 2-3주

### Week 11: 소셜 로그인 & 사진 첨부

#### 소셜 로그인
- [ ] Apple Sign In 구현
- [ ] Google Sign In 구현

#### 사진 첨부
**기능:**
- [ ] 답변에 사진 첨부
- [ ] 이미지 업로드 서비스
- [ ] 이미지 캐싱
- [ ] 이미지 프리뷰

**Data Layer:**
- [ ] ImageUploadService 구현
- [ ] S3 또는 Firebase Storage 연동

---

### Week 12: 알림 커스터마이징 & 설정

#### 알림 설정
- [ ] 알림 on/off
- [ ] 알림 시간 설정
- [ ] 알림 타입별 on/off

#### 설정 화면
- [ ] SettingsFeature 구현
- [ ] SettingsView 구현
- [ ] 프로필 편집
- [ ] 알림 설정
- [ ] 계정 관리

---

### Week 13: 통계 & 인사이트

#### 가족 활동 통계
- [ ] 총 답변 수
- [ ] 연속 답변 일수
- [ ] 가장 활발한 구성원
- [ ] 카테고리별 답변 통계

#### 인사이트
- [ ] 가장 인상 깊었던 답변
- [ ] 월간 하이라이트
- [ ] 성장 그래프

---

## Phase 4: 고급 기능 (추후)

### 질문 커스터마이징
- [ ] 가족이 직접 질문 추가
- [ ] 질문 투표 시스템
- [ ] 특별 기념일 질문

### 다국어 지원
- [ ] 영어 지원
- [ ] 일본어 지원
- [ ] 중국어 지원

### 여러 가족 그룹
- [ ] 한 사용자가 여러 가족 그룹 가입
- [ ] 그룹 전환 UI
- [ ] 그룹별 나무 관리

### AI 기능
- [ ] AI 질문 추천
- [ ] 답변 패턴 분석
- [ ] 맞춤 질문 생성

---

## 개발 우선순위

### P0 (필수)
- 인증 시스템
- 가족 그룹 생성/참여
- 질문-답변 시스템
- 기본 나무 시각화
- 푸시 알림

### P1 (중요)
- 반응 & 댓글
- 나무 성장 고도화
- 배지 시스템
- 과거 질문 아카이브

### P2 (추가)
- 소셜 로그인
- 사진 첨부
- 알림 커스터마이징
- 통계 & 인사이트

### P3 (미래)
- 질문 커스터마이징
- 다국어 지원
- 여러 가족 그룹
- AI 기능

---

## 테스트 계획

### Unit Tests
- [ ] All UseCases
- [ ] Entity business logic
- [ ] Mappers
- [ ] Validation logic

### Integration Tests
- [ ] Repository implementations
- [ ] API Services
- [ ] Data flow

### UI Tests
- [ ] TCA Features (TestStore)
- [ ] Critical user flows
- [ ] Snapshot tests

### E2E Tests
- [ ] Complete user journey
  - Signup → Create Family → Answer Question → View Answers → Tree Growth

---

## 품질 관리

### 코드 리뷰
- [ ] PR 리뷰 체크리스트 작성
- [ ] 2명 이상 승인 필요
- [ ] 테스트 커버리지 70% 이상

### 성능 최적화
- [ ] 이미지 최적화
- [ ] 네트워크 요청 최적화
- [ ] 메모리 사용량 모니터링

### 보안
- [ ] API 키 관리
- [ ] 사용자 데이터 암호화
- [ ] HTTPS 통신

---

## 배포 계획

### Beta Testing
- [ ] TestFlight 배포
- [ ] 베타 테스터 모집 (10-20명)
- [ ] 피드백 수집 및 반영

### App Store Release
- [ ] 앱 스토어 메타데이터 준비
- [ ] 스크린샷 준비
- [ ] 앱 리뷰 제출
- [ ] 출시

---

## 마일스톤

| 마일스톤 | 목표일 | 주요 deliverable |
|---------|--------|------------------|
| M1: MVP 완료 | Week 6 | 핵심 기능 동작하는 첫 버전 |
| M2: Phase 2 완료 | Week 10 | 반응/댓글, 배지, 히스토리 |
| M3: Phase 3 완료 | Week 13 | 소셜 로그인, 사진, 설정 |
| M4: Beta Release | Week 14 | TestFlight 배포 |
| M5: App Store Release | Week 16 | 정식 출시 |

---

## 리스크 관리

### 기술적 리스크
- **TCA 학습 곡선**: TCA 튜토리얼 먼저 학습
- **네트워크 안정성**: Offline-first 아키텍처 고려
- **푸시 알림 신뢰성**: 로컬 알림 fallback

### 일정 리스크
- **기능 범위 확대**: MVP 범위 엄격히 관리
- **예상치 못한 버그**: 버퍼 시간 확보

---

**작성일**: 2025-12-08
**버전**: 1.0.0
**다음 업데이트**: Week 1 완료 후
