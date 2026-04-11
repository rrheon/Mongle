# Mongle (FamTree) — 프로젝트 에이전트 지침

Mongle은 가족 소통 앱(앱스토어 v1 출시 완료)이며, YCompany 산하 서브 프로젝트로 운영됩니다. 본 지침은 `/Users/yong/Desktop/YCompany/CLAUDE.md` (YCompany 팀 리드 지침)를 **상속**하며, Mongle 고유 사항만 이 파일에 기록합니다.

---

## 1. 위치

| 구성 | 경로 |
| :--- | :--- |
| iOS | `/Users/yong/Desktop/FamTree` (이 파일 위치) |
| Android | `/Users/yong/Mongle-Android` |
| 서버 | `/Users/yong/Desktop/MongleServer` (Node.js + TypeScript + Prisma) |
| 디자인 | `/Users/yong/Desktop/FamTree/MongleUI.pen` |
| 법률 문서 원문 | `/Users/yong/Desktop/FamTree/Legal/{privacy-policy,terms}-{ko,en,ja}.md` |

> Mongle은 YCompany 디렉토리 규칙의 예외입니다. v1이 이미 스토어에 배포되어 있어 루트를 이동하지 않습니다.

---

## 2. 기술 스택 — 예외 사항

- **iOS는 TCA 사용.** YCompany 공통 규칙 "iOS = SwiftUI + MVVM, TCA 금지"의 **예외**입니다. 이유: v1이 이미 TCA 기반으로 출시되어 있고, 재작성 비용이 v2 범위를 초과합니다. v2에서도 TCA 유지.
- **Android는 Compose + MVVM.** 공통 규칙과 동일.
- **서버는 TypeScript + Express/tsoa + Prisma.**

---

## 3. 노션

- 부모 페이지: `🌱 Mongle` (`33f4a57d-5a46-8110-83d0-d18a7223cf69`)
- 티켓 DB: `Mongle Tickets`
- `data_source_id`: `2f2be0a6-a38f-4f9f-8de7-3e99c5bc3f12`
- 티켓 prefix: **MG**
- 카테고리 예시: `[Mongle] 0. 에픽`, `[Foundation]`, `[Engine]`, `[UI]`, `[Catalog]`, `[QA]`, `[Docs]`, `[Bugfix]`

## 4. 팀

- 팀 이름: `ycompany-mongle`
- 위치: `~/.claude/teams/ycompany-mongle/config.json`
- 기본 멤버: team-lead, planner, ios-dev, android-dev, server-dev, qa

## 5. 핵심 도메인 메모

- **streak**: 서버 `GET /users/me/streak` 존재 (`src/services/UserService.ts:152`). 가족 streak은 `FamilyService.getFamilyStreakDays`.
- **iOS 엔트리**: `FamTree/FamTreeApp.swift`, Feature 계층은 `MongleFeatures/Sources/MongleFeatures/Presentation/`.
- **홈 캐릭터 뷰**: `MongleFeatures/.../Presentation/Home/HomeView.swift`.
- **Settings legal section**: `Presentation/Settings/SettingsTabView.swift:197-232` (`LegalLinks.termsURL`, `privacyURL`).
- **로컬라이즈**: `MongleFeatures/Sources/MongleFeatures/Resources/{ko,en,ja}.lproj/Localizable.strings`.

## 6. v2 범위 (2026-04-11 시점)

1. **몽글캐릭터 단계별 크기 증가** — 개인 streak 기반 성장 시스템 (planner PRD 예정)
2. **기타 추가 기능** — 사용자 확정 후 PRD에 반영

> Privacy/ToS 섹션 추가 요청은 현재 양 플랫폼에 이미 웹링크로 구현되어 있어 v2 작업에서 제외.
