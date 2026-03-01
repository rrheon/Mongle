//
//  Untitled.swift
//  FTFeatures
//
//  Created by 최용헌 on 1/22/26.
//

import SwiftUI

// MARK: - TopBar State Models

struct HomeTopBarState {
    var streakDays: Int
    var groupName: String
    var level: Int
    var currentXP: Int
    var maxXP: Int
    var hasNotification: Bool
    var todayQuestion: TopBarQuestion?

    var levelName: String {
        switch level {
        case 1: return "Tiny Hedgehogs"
        case 2: return "Growing Meadow"
        case 3: return "Cozy Forest"
        case 4: return "Warm Woodland"
        case 5: return "Golden Meadow"
        default: return "Legendary Meadow"
        }
    }

    static let preview = HomeTopBarState(
        streakDays: 5,
        groupName: "Kim Family",
        level: 3,
        currentXP: 420,
        maxXP: 500,
        hasNotification: true,
        todayQuestion: TopBarQuestion(
            id: UUID(),
            text: "What made you smile today?",
            isAnswered: false
        )
    )
}

struct TopBarQuestion: Identifiable {
    let id: UUID
    let text: String
    let isAnswered: Bool
}

// MARK: - Meadow Hedgehog Data Model

private struct MeadowHedgehog: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    var hasAnswered: Bool
    var position: CGPoint
    var targetPosition: CGPoint
    var overlapCounter: Int = 0  // 충돌 지속 프레임 수
    var stepCount: Int = 0       // 이동 누적 스텝 수 (hop 위상 계산용)
}

// MARK: - Main View

struct MeadowHomeView: View {
    @State private var topBarState = HomeTopBarState.preview

    var body: some View {
        ZStack {
            // 🌿 Background Meadow
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.98, blue: 0.90),
                    Color(red: 0.80, green: 0.93, blue: 0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // HUD TopBar
                TopBarView(state: topBarState)

                Spacer(minLength: 12)

                // Meadow Scene
                MeadowSceneView()

                Spacer()

                // Bottom CTA
                FooterButtonView()
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - TopBar View (HUD 3단 구조)

struct TopBarView: View {
    let state: HomeTopBarState
    var onQuestionTap: () -> Void = { print("질문 카드 탭") }
    var onNotificationTap: () -> Void = { print("알림 탭") }

    var body: some View {
        VStack(spacing: 10) {
            // 1단: Streak | 그룹명 | 알림
            StatusHUDView(
                streakDays: state.streakDays,
                groupName: state.groupName,
                hasNotification: state.hasNotification,
                onNotificationTap: onNotificationTap
            )

            // 2단: XP Bar
            XPBarView(
                level: state.level,
                levelName: state.levelName,
                currentXP: state.currentXP,
                maxXP: state.maxXP
            )

            // 3단: 오늘의 질문 카드
            if let question = state.todayQuestion {
                TodayQuestionCard(question: question, onTap: onQuestionTap)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 52)
        .padding(.bottom, 8)
    }
}

// MARK: - 1단: Status HUD

private struct StatusHUDView: View {
    let streakDays: Int
    let groupName: String
    let hasNotification: Bool
    var onNotificationTap: () -> Void

    var body: some View {
        HStack {
            StreakBadgeView(days: streakDays)
            Spacer()
            Text(groupName)
                .font(.headline.bold())
            Spacer()
            NotificationButtonView(hasNotification: hasNotification, onTap: onNotificationTap)
        }
    }
}

private struct StreakBadgeView: View {
    let days: Int

    @State private var scale: CGFloat = 1.0

    // 7일 미만: 주황, 7일 이상: 오렌지, 30일 이상: 골드
    private var badgeColor: Color {
        if days >= 30 { return Color(red: 1.0, green: 0.75, blue: 0.0) }
        if days >= 7  { return .orange }
        return Color(red: 0.95, green: 0.5, blue: 0.2)
    }

    var body: some View {
        HStack(spacing: 5) {
            Text("🔥")
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(days) Days")
                    .font(.caption.bold())
                    .foregroundColor(badgeColor)
                Text("Streak")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(badgeColor.opacity(0.15))
                .overlay(Capsule().stroke(badgeColor.opacity(0.35), lineWidth: 1))
        )
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                scale = 1.06
            }
        }
    }
}

private struct NotificationButtonView: View {
    let hasNotification: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())

                if hasNotification {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 2단: XP Bar

private struct XPBarView: View {
    let level: Int
    let levelName: String
    let currentXP: Int
    let maxXP: Int

    @State private var progress: CGFloat = 0

    private var xpRatio: CGFloat {
        guard maxXP > 0 else { return 0 }
        return min(CGFloat(currentXP) / CGFloat(maxXP), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Text("Lv.\(level)")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                    Text(levelName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(currentXP) / \(maxXP) XP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.green, Color(red: 0.2, green: 0.75, blue: 0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            withAnimation(.spring(duration: 1.0, bounce: 0.25)) {
                progress = xpRatio
            }
        }
    }
}

// MARK: - 3단: 오늘의 질문 카드

private struct TodayQuestionCard: View {
    let question: TopBarQuestion
    var onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button { onTap() } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("🌿")
                            .font(.caption)
                        Text("Today's Question")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        if question.isAnswered {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    Text(question.text)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Meadow Scene (구역 내 이동 + 충돌 감지)
struct MeadowSceneView: View {
    // 현재 사용자가 오늘 질문에 답변했는지 여부
    var hasCurrentUserAnswered: Bool = false
    var onViewAnswer: (String) -> Void = { name in print("\(name)의 답변 보기") }
    var onAnswerQuestion: () -> Void = { print("답변하기 화면으로 이동") }

    private let stepSize: CGFloat = 2.0
    private let interval: TimeInterval = 0.12
    private let collisionRadius: CGFloat = 58
    private let targetThreshold: CGFloat = 12
    private let wallPadding: CGFloat = 50
    private let overlapLimit: Int = 10  // ~1.2초 충돌 지속 후 새 목표 설정

    @State private var hedgehogs: [MeadowHedgehog] = []
    @State private var timer: Timer?

    private static let memberData: [(String, Color, Bool)] = [
        ("Dad", .orange, true),
        ("Mom", .green, false),
        ("Lily", .yellow, true),
        ("Ben", .blue, false),
        ("Alex", .pink, true)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Ground shadow
                Ellipse()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 260, height: 80)
                    .blur(radius: 16)
                    .position(x: geo.size.width / 2, y: geo.size.height - 10)

                ForEach(hedgehogs) { h in
                    // stepCount 기반 포물선 hop: 5스텝(0.6초)마다 한 번 튀어오름
                    let hopY = -abs(sin(CGFloat(h.stepCount) * .pi / 5.0)) * 12
                    HedgehogView(
                        name: h.name,
                        color: h.color,
                        hasAnswered: h.hasAnswered,
                        hasCurrentUserAnswered: hasCurrentUserAnswered,
                        onViewAnswer: { onViewAnswer(h.name) },
                        onAnswerQuestion: onAnswerQuestion
                    )
                    .position(CGPoint(x: h.position.x, y: h.position.y + hopY))
                    .animation(.linear(duration: interval), value: h.stepCount)
                }
            }
            .onAppear {
                if hedgehogs.isEmpty {
                    initHedgehogs(size: geo.size)
                }
                startTimer(size: geo.size)
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
        .frame(height: 300)
    }

    private func initHedgehogs(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        // 초기 위치가 겹치지 않도록 최대 30회 재시도
        var placed: [CGPoint] = []
        hedgehogs = Self.memberData.map { name, color, hasAnswered in
            var pos = randomPos(size: size)
            for _ in 0..<30 {
                let overlaps = placed.contains { hypot(pos.x - $0.x, pos.y - $0.y) < collisionRadius }
                if !overlaps { break }
                pos = randomPos(size: size)
            }
            placed.append(pos)
            return MeadowHedgehog(
                name: name,
                color: color,
                hasAnswered: hasAnswered,
                position: pos,
                targetPosition: randomPos(size: size)
            )
        }
    }

    private func randomPos(size: CGSize) -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: wallPadding...(size.width - wallPadding)),
            y: CGFloat.random(in: wallPadding...(size.height - wallPadding))
        )
    }

    private func startTimer(size: CGSize) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            step(size: size)
        }
    }

    private func step(size: CGSize) {
        for i in hedgehogs.indices {
            var pos = hedgehogs[i].position
            let target = hedgehogs[i].targetPosition
            let dx = target.x - pos.x
            let dy = target.y - pos.y
            let dist = hypot(dx, dy)

            // 목표 도달 → 새 목표 설정
            if dist < targetThreshold {
                hedgehogs[i].targetPosition = randomPos(size: size)
                continue
            }

            // 목표 방향으로 한 걸음 이동
            pos.x += (dx / dist) * stepSize
            pos.y += (dy / dist) * stepSize

            // 벽 충돌 → 위치 보정 + 새 목표
            if pos.x < wallPadding || pos.x > size.width - wallPadding ||
               pos.y < wallPadding || pos.y > size.height - wallPadding {
                pos.x = min(max(pos.x, wallPadding), size.width - wallPadding)
                pos.y = min(max(pos.y, wallPadding), size.height - wallPadding)
                hedgehogs[i].targetPosition = randomPos(size: size)
            }

            // 다른 고슴도치와 충돌 → overlapLimit 프레임 초과 시 새 목표 설정
            let collides = hedgehogs.indices.contains { j in
                guard j != i else { return false }
                return hypot(pos.x - hedgehogs[j].position.x,
                             pos.y - hedgehogs[j].position.y) < collisionRadius
            }
            if collides {
                hedgehogs[i].overlapCounter += 1
                if hedgehogs[i].overlapCounter >= overlapLimit {
                    hedgehogs[i].targetPosition = randomPos(size: size)
                    hedgehogs[i].overlapCounter = 0
                }
                // 이번 프레임은 위치 갱신 없이 다음 프레임 재시도
                continue
            }

            hedgehogs[i].overlapCounter = 0
            hedgehogs[i].stepCount += 1
            hedgehogs[i].position = pos
        }
    }
}

// MARK: - Hedgehog Component (버튼 포함)
struct HedgehogView: View {
    let name: String
    let color: Color
    let hasAnswered: Bool
    let hasCurrentUserAnswered: Bool
    let onViewAnswer: () -> Void
    let onAnswerQuestion: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            // 상단 버튼: 답변 여부에 따라 다른 스타일
            if hasAnswered {
                // 이 고슴도치가 답변한 경우
                // 1) 본인도 답변한 경우 → 답변 보기
                // 2) 본인이 답변하지 않은 경우 → 답변하기
                Button(action: hasCurrentUserAnswered ? onViewAnswer : onAnswerQuestion) {
                    HStack(spacing: 4) {
                        Image(systemName: hasCurrentUserAnswered ? "bubble.left.fill" : "pencil")
                            .font(.system(size: 10, weight: .bold))
                        Text(hasCurrentUserAnswered ? "답변 보기" : "답변하기")
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(hasCurrentUserAnswered ? Color.green : Color.orange)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            } else {
                // 이 고슴도치가 아직 답변하지 않은 경우
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("미답변")
                        .font(.caption2.bold())
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.4))
                .foregroundColor(.white)
                .clipShape(Capsule())
            }

            // 고슴도치 캐릭터
            Circle()
                .fill(color)
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                )
                .overlay(
                    Text("• •")
                        .font(.caption)
                        .offset(y: -2)
                )
                .shadow(radius: 4)

            Text(name)
                .font(.caption2.bold())
        }
    }
}

// MARK: - Footer Button
struct FooterButtonView: View {
  var body: some View {
    Button {
      print("See recap tapped")
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "book.fill")
        Text("See Today's Recap")
          .bold()
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color.green)
      .foregroundColor(.black)
      .clipShape(Capsule())
    }
    .padding(.horizontal)
  }
}

// MARK: - Preview
#Preview {
  MeadowHomeView()
}
