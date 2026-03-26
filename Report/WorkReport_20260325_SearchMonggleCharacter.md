# 작업 보고서 - 검색 셀 몽글캐릭터 HomeView와 통일

**날짜:** 2026-03-25

---

## 문제

검색 화면의 검색 셀(`SearchResultCard`) 안에 표시되는 몽글캐릭터가 HomeView의 몽글캐릭터(`MongleMonggle`)와 외형이 다름.

**원인:**
- `MiniMongleAvatar`가 `Circle()` + 두 개의 눈 점(검은 원)으로 직접 구현된 간이 캐릭터를 사용
- HomeView는 공용 컴포넌트 `MongleMonggle`을 사용

---

## 수정 내용

### `SearchHistoryView.swift` — `MiniMongleAvatar` 본체 교체

```swift
// 수정 전
var body: some View {
    let color = Self.colors[colorIndex % Self.colors.count]
    Circle()
        .fill(color)
        .frame(width: 32, height: 32)
        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        .overlay(
            HStack(spacing: 5) {
                Circle().fill(Color.black.opacity(0.7)).frame(width: 4, height: 4)
                Circle().fill(Color.black.opacity(0.7)).frame(width: 4, height: 4)
            }
            .offset(y: -1)
        )
}

// 수정 후
var body: some View {
    let color = Self.colors[colorIndex % Self.colors.count]
    MongleMonggle(color: color, size: 32)
}
```

- 기존 인터페이스(`colorIndex: Int`) 유지 — `AnswerRow` 및 색상 매핑 변경 없음
- 색상은 기존과 동일하게 `moodId → colorIndex → Color`로 변환
- 캐릭터 외형만 `MongleMonggle`로 통일

---

## 변경 파일 요약

| 파일 | 변경 내용 |
|------|----------|
| `Search/SearchHistoryView.swift` | `MiniMongleAvatar.body`를 `MongleMonggle(color:size:)`로 교체 |
