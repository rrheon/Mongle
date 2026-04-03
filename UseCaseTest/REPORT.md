# Mongle (몽글) iOS / Android UseCase 검증 및 비교 보고서

**작성일**: 2026-04-01  
**프로젝트**: Mongle (가족/친구 일상 소통 앱)

---

## 1. 작업 개요

### 1.1 목적
- 각 화면별 UseCase를 작성하여 앱 흐름을 체계적으로 정리
- iOS와 Android 프로젝트의 UI/로직 일관성 검증
- iOS 기준으로 Android의 불일치 사항 수정

### 1.2 프로젝트 위치
| 구분 | 경로 |
|------|------|
| iOS (SwiftUI + TCA) | `/Users/yong/Desktop/FamTree` |
| Android (Compose + MVVM) | `/Users/yong/Mongle-Android` |
| 디자인 | `/Users/yong/Desktop/FamTree/MongleUI.pen` |

---

## 2. UseCase 작성 결과

총 **11개 화면**, **42개 UseCase** 작성 완료.

| 파일 | 화면 | UseCase 수 |
|------|------|-----------|
| UC01_온보딩.md | 온보딩 | 3 |
| UC02_로그인.md | 로그인 | 4 |
| UC03_그룹선택.md | 그룹 선택/생성/참여 | 5 |
| UC04_홈.md | 홈 | 10 |
| UC05_질문상세.md | 질문 상세 | 3 |
| UC06_질문작성.md | 질문 작성 | 2 |
| UC07_히스토리.md | 히스토리 | 4 |
| UC08_검색.md | 검색 | 3 |
| UC09_알림.md | 알림 | 5 |
| UC10_넛지.md | 넛지/재촉 | 3 |
| UC11_프로필설정.md | 프로필/설정 | 8 |

UseCase 파일은 양쪽 프로젝트의 `UseCaseTest/` 폴더에 동일하게 배치:
- iOS: `/Users/yong/Desktop/FamTree/UseCaseTest/`
- Android: `/Users/yong/Mongle-Android/UseCaseTest/`

---

## 3. iOS ↔ Android 비교 결과

### 3.1 디자인 시스템 차이 (수정 완료)

#### 색상 (Color)
| 항목 | iOS (수정 전 Android) | iOS 기준값 | 상태 |
|------|----------------------|-----------|------|
| Primary | `#8FD5A6` → | `#4CAF50` | **수정 완료** |
| PrimaryDark | `#A5E0C0` → | `#388E3C` | **수정 완료** |
| PrimaryLight | `#EDF7F0` → | `#A5D6A7` | **수정 완료** |
| PrimarySoft | `#BDE5C0` → | `#43A047` | **수정 완료** |
| Background | `#FFF5F0` (피치톤) → | `#F8FAF8` (그린톤) | **수정 완료** |
| Surface | `#F5F4F1` → | `#FDF8F5` | **수정 완료** |
| Success | `#7CC8A0` → | `#4CAF50` | **수정 완료** |
| MonggleGreen | `#8FD5A6` → | `#66BB6A` | **수정 완료** |
| CoralLight | `#FF7043` → | `#FF8A80` | **수정 완료** |
| GoogleBorder | `#DEDEDE` → | `#747775` | **수정 완료** |

#### 추가된 색상 (Android에 없었던 것)
- `MonglePrimaryGradientStart/End`, `MonglePrimaryXLight`, `MonglePrimaryMuted`, `MonglePrimaryDeep`
- `MongleBgNeutral`, `MongleBgCreamy`, `MongleBgWarm` 등 15개 배경색
- `MongleGradientBgStart/Mid/End` (앱 배경 그라데이션)
- `MongleCardBackgroundSolid`, `MongleCardGlass` (카드 변형)
- `MongleBorderWarm` (따뜻한 테두리)
- `MongleHeartPink/PastelLight` 등 4개 하트 색상
- `MongleBrown`, `MonglePageIndicatorInactive`, `MongleCalendarSunday` 등

#### 타이포그래피 (Typography)
| 스타일 | 수정 전 Android | iOS 기준 | 상태 |
|--------|----------------|---------|------|
| heading1 | 28sp Bold | 28sp **ExtraBold** | **수정 완료** |
| heading2 | **24sp** Bold | **22sp** SemiBold | **수정 완료** |
| heading3 | **20sp** SemiBold | **18sp** SemiBold | **수정 완료** |
| body1 | **16sp** Normal | **15sp** Medium | **수정 완료** |

#### 추가된 스타일
- `MongleFontStyle.body1Bold` (15sp SemiBold)
- `MongleFontStyle.body2Bold` (14sp SemiBold)
- `MongleFontStyle.captionBold` (12sp SemiBold)

#### 추가된 토큰
- `MongleSpacing` (xxs=4, xs=8, sm=12, md=16, lg=24, xl=32, xxl=48)
- `MongleRadius` (xs=4, small=8, medium=12, large=16, xl=20, xxl=24, full=100)

---

### 3.2 홈 화면 차이 (수정 완료)

| 항목 | 수정 전 Android | iOS 기준 | 상태 |
|------|----------------|---------|------|
| 하트 버튼 배경색 | `MongleHeartRedLight` (빨간) | `bgNeutral` (중립 회색) | **수정 완료** |
| 하트 충전 안내 | "답변 완료 **+1**" | "답변 완료 **+3**" | **수정 완료** |
| 나만의 질문 아이콘 | `CheckCircle` | `Create` (연필) | **수정 완료** |
| 재촉하기 아이콘 | `Favorite` (하트) | `Campaign` (확성기) | **수정 완료** |
| 플레이스홀더 시간 | "오후 12시에 다시 질문을 받을 수 있어요" | "오전 11시에 새로운 질문이 도착해요" | **수정 완료** |
| 하트 말풍선 너비 | 230dp | 220dp (iOS: 220pt) | **수정 완료** |

---

### 3.3 로그인 화면 차이 (수정 완료)

| 항목 | 수정 전 Android | iOS 기준 | 상태 |
|------|----------------|---------|------|
| 배경 | 3색 그라데이션 | 단색 `background` | **수정 완료** |
| 에러 표시 | 인라인 텍스트 (빨간색) | 토스트 오버레이 (2초 자동 사라짐) | **수정 완료** |
| 버튼 간격 | `MongleSpacing.sm` (12dp) | `MongleSpacing.md` (16dp) | **수정 완료** |

---

### 3.4 미수정 차이점 (추후 작업 필요)

#### 기능적 차이 (iOS에만 있는 기능)
| 항목 | 설명 | 우선순위 |
|------|------|---------|
| Apple 로그인 | Android에서 미구현 ("준비 중" 메시지) | 높음 |
| 게스트 모드 보호 | iOS는 모든 주요 액션에서 "로그인이 필요해요" 팝업 | 높음 |
| 알림 권한 요청 | iOS는 그룹별 1회 알림 허용 팝업 | 중간 |
| 미읽은 알림 표시 | iOS는 벨 아이콘에 빨간 점, Android는 항상 false | 중간 |
| 광고 배너 | iOS 검색 결과에 11건마다 광고 삽입 | 낮음 |
| 스와이프 삭제 | iOS 알림에서 개별 스와이프 삭제 | 낮음 |
| Pull-to-refresh | iOS 알림에서 당겨서 새로고침 | 낮음 |

#### 기능적 차이 (Android에만 있는 기능)
| 항목 | 설명 | 조치 |
|------|------|------|
| 네이버 로그인 | Android에 버튼 존재 (미구현) | iOS에 없으므로 제거 검토 |
| 이메일 로그인 | ViewModel에 전체 구현 | iOS에 없으므로 동기화 필요 |
| 둘러보기 데모 캐릭터 | 5명 데모 캐릭터 자동 생성 | iOS에 없으므로 제거 검토 |
| 이름 변경 7일 쿨다운 | Android에만 존재 | iOS에 추가 또는 Android에서 제거 |

#### UI 세부 차이 (낮은 우선순위)
| 화면 | 차이점 |
|------|--------|
| 온보딩 | OB2 멤버 수: iOS 4명 vs Android 5명, 마지막 버튼에 Android만 이모지 포함 |
| 그룹선택 | iOS에 알림 권한/방해금지 step 존재, Android에 없음 |
| 질문상세 | iOS는 질문 카드에 border, Android는 없음; CTA 그라데이션 색상 다름 |
| 검색 | iOS는 clear 버튼(X), Android는 없음; iOS는 로고, Android는 검색 아이콘 |
| 알림 | iOS는 타입별 다른 아이콘, Android는 단일 아이콘; iOS에만 스와이프 삭제 |
| 넛지 | 전체 레이아웃 상이 (iOS: 질문카드+빈상태+넛지카드 3섹션, Android: 단순 구조) |
| 프로필 | iOS에 광고 배너/기분 히스토리/몽글카드 편집 존재 |

---

## 4. 수정 파일 목록

| 파일 | 수정 내용 |
|------|----------|
| `Mongle-Android/app/.../ui/theme/Color.kt` | Primary 색상 체계 전면 교체, 배경/카드/보더/하트 등 iOS 기준 동기화, 누락 색상 25개+ 추가 |
| `Mongle-Android/app/.../ui/theme/Type.kt` | heading1~body1 크기/웨이트 수정, Bold 변형 3개 추가, Spacing/Radius 토큰 추가 |
| `Mongle-Android/app/.../ui/home/HomeScreen.kt` | 하트 버튼 배경, 충전량 텍스트, 아이콘 2개, 플레이스홀더 시간, 말풍선 너비 수정 |
| `Mongle-Android/app/.../ui/login/LoginScreen.kt` | 배경 단색 변경, 에러 토스트 방식 변경, 버튼 간격 수정 |

---

## 5. 아키텍처 비교 요약

| 항목 | iOS | Android |
|------|-----|---------|
| UI 프레임워크 | SwiftUI | Jetpack Compose |
| 상태 관리 | TCA (ComposableArchitecture) | MVVM + StateFlow |
| DI | @Dependency 매크로 | Hilt |
| 네비게이션 | NavigationStack + path | 콜백 기반 state routing |
| 데이터 레이어 | Clean Architecture (Domain/Data 분리) | 유사 Clean Architecture |
| 폰트 | SUIT 커스텀 폰트 | 시스템 기본 (SUIT 미적용) |
| 에러 처리 | AppError 래퍼 + mongleErrorToast | String? + 인라인/토스트 혼재 |

---

## 6. 권장 후속 작업

### 높음 (P0)
1. **SUIT 폰트 Android 적용** - iOS와 동일한 SUIT 폰트를 Android에 번들링
2. **게스트 모드 보호** - Android에 iOS와 동일한 "로그인 필요" 팝업 추가
3. **미읽은 알림 뱃지** - Android `hasNotification` 하드코딩 제거, 실제 API 연동

### 중간 (P1)
4. **알림 화면 아이콘 차별화** - 알림 타입별 다른 아이콘 적용
5. **넛지 화면 레이아웃** - iOS 3섹션 구조로 Android 재설계
6. **네이버 로그인 버튼 제거** - iOS에 없으므로 정리

### 낮음 (P2)
7. **검색 화면 clear 버튼** 추가
8. **온보딩 OB2 멤버 수** 통일 (4명)
9. **광고 배너** Android 검색/프로필에 추가

---

## 7. 결론

iOS와 Android 프로젝트의 핵심 불일치를 파악하고 **디자인 시스템(색상 30개+, 타이포그래피 4개 스타일, Spacing/Radius 토큰)** 및 **주요 화면(홈, 로그인)의 UI/텍스트**를 iOS 기준으로 수정했습니다. 

수정된 Color.kt와 Type.kt는 향후 모든 Android 화면에 영향을 미치므로, 빌드 후 전체 화면 시각 점검이 필요합니다. 기능적 차이(게스트 모드 보호, 알림 뱃지, 넛지 레이아웃 등)는 별도 작업으로 진행하는 것을 권장합니다.
