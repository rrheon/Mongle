# 작업 보고서 - GroupSelect 화면 연속기록 구현

**날짜:** 2026-03-25

---

## 문제

GroupSelect 화면에서 어제·오늘 모든 멤버가 답변했음에도 "0일연속" 뱃지가 표시됨.

**원인:** `GroupSelectView+Select.swift`의 `MongleCardGroup(streakDays: 0)` 하드코딩.
그룹 전원 답변 기준 연속기록 API가 존재하지 않았음.

---

## 구현 내용

### 서버 (`/Users/yong/Desktop/FamTreeServer`)

#### 1. `src/models/index.ts`
`FamilyResponse` 인터페이스에 `streakDays: number` 추가

#### 2. `src/services/FamilyService.ts`
- `getMyFamilies()`: 각 가족별 `streakDays` 계산 후 응답에 포함
- `getFamilyStreakDays(familyId, memberIds)` private 메서드 추가

**그룹 streak 알고리즘:**
1. 해당 가족의 최근 60일 `DailyQuestion` + 멤버 `Answer` 조회
2. 날짜별 답변한 멤버 ID 집합 구성
3. 오늘 또는 어제 모든 멤버가 답변했는지 확인 (시작 날짜 결정)
4. 시작 날짜부터 과거로 소급하며 전원 답변 날 수 연속 카운트
5. 전원 미답변 날 발견 시 중단

```typescript
private async getFamilyStreakDays(familyId: string, memberIds: string[]): Promise<number>
```

#### 3. `src/routes/routes.ts`
`FamilyResponse` 스키마에 `"streakDays": {"dataType":"double","required":true}` 추가

---

### iOS (`/Users/yong/Desktop/FamTree`)

#### 1. `Domain/Sources/Domain/Entities/FamilyGroup.swift`
`MongleGroup`에 `streakDays: Int` 프로퍼티 추가 (기본값 `0`)

#### 2. `MongleData/Sources/MongleData/DTOs/FamilyDTO.swift`
`FamilyResponseDTO`에 `streakDays: Int?` 추가

#### 3. `MongleData/Sources/MongleData/Mappers/FamilyMapper.swift`
`toDomainWithMembers`에서 `streakDays: dto.streakDays ?? 0` 매핑

#### 4. `MongleFeatures/.../GroupSelectView+Select.swift`
하드코딩 `0` 제거, 실제 값 사용:
```swift
// 수정 전
streakDays: 0,

// 수정 후
streakDays: group.streakDays > 0 ? group.streakDays : nil,
```
streak이 0이면 `nil` → 뱃지 미표시, 1 이상이면 "N일 연속" 표시

---

## 동작 방식

- 오늘 또는 어제 기준으로 **모든 멤버가 답변한 날이 연속**되는 일 수 계산
- 하루만 전원 답변 → **1일 연속** 표시
- 전원 미답변 날(또는 스킵된 날)이 있으면 streak 초기화
- streak = 0이면 뱃지 숨김

---

## 변경 파일 요약

| 파일 | 변경 내용 |
|------|----------|
| `FamTreeServer/src/models/index.ts` | `FamilyResponse.streakDays: number` 추가 |
| `FamTreeServer/src/services/FamilyService.ts` | 그룹 streak 계산 로직 추가 |
| `FamTreeServer/src/routes/routes.ts` | 스키마 업데이트 |
| `Domain/.../FamilyGroup.swift` | `MongleGroup.streakDays: Int` 추가 |
| `MongleData/.../FamilyDTO.swift` | `FamilyResponseDTO.streakDays: Int?` 추가 |
| `MongleData/.../FamilyMapper.swift` | streakDays 매핑 추가 |
| `MongleFeatures/.../GroupSelectView+Select.swift` | 하드코딩 0 → 실제 값 사용 |
