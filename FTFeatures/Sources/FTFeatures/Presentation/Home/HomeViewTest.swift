//
//  Untitled.swift
//  FTFeatures
//
//  Created by 최용헌 on 1/22/26.
//

import SwiftUI

// MARK: - Data Model

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

        // Top Bar
        TopBarView()

        Spacer(minLength: 16)

        // Title
        HeaderView()

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

// MARK: - Top Bar
struct TopBarView: View {
  var body: some View {
    HStack {
      Circle()
        .fill(Color.green.opacity(0.25))
        .frame(width: 36, height: 36)
        .overlay(
          Image(systemName: "leaf.fill")
            .foregroundColor(.green)
        )

      Spacer()

      Text("EVERYONE ANSWERED")
        .font(.caption.bold())
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())

      Spacer()

      Image(systemName: "bell")
        .frame(width: 36, height: 36)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
    }
    .padding(.horizontal)
    .padding(.top, 44)
  }
}

// MARK: - Header
struct HeaderView: View {
  var body: some View {
    VStack(spacing: 6) {
      Text("Our family is together")
        .font(.title3.bold())

      Text("5 hedgehogs in the meadow")
        .font(.caption)
        .foregroundColor(.green)
    }
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
        .frame(height: 320)
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
