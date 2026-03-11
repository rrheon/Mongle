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
  var hasNotification: Bool
  var todayQuestion: TopBarQuestion?

  static let preview = HomeTopBarState(
    streakDays: 5,
    groupName: "Kim Family",
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

// MARK: - Main View

struct HomeView: View {
  let topBarState: HomeTopBarState
  let hasCurrentUserAnswered: Bool
  var onQuestionTap: () -> Void
  var onNotificationTap: () -> Void
  var onHeartsTap: () -> Void
  var onPeerAnswerTap: (String) -> Void   // 화면이동: 답변 보기
  var onPeerNudgeTap: (String) -> Void    // 화면이동: 재촉하기

  init(
    topBarState: HomeTopBarState = .preview,
    hasCurrentUserAnswered: Bool = false,
    onQuestionTap: @escaping () -> Void = {},
    onNotificationTap: @escaping () -> Void = {},
    onHeartsTap: @escaping () -> Void = {},
    onPeerAnswerTap: @escaping (String) -> Void = { _ in },
    onPeerNudgeTap: @escaping (String) -> Void = { _ in }
  ) {
    self.topBarState = topBarState
    self.hasCurrentUserAnswered = hasCurrentUserAnswered
    self.onQuestionTap = onQuestionTap
    self.onNotificationTap = onNotificationTap
    self.onHeartsTap = onHeartsTap
    self.onPeerAnswerTap = onPeerAnswerTap
    self.onPeerNudgeTap = onPeerNudgeTap
  }
  
  var body: some View {
    VStack(spacing: 0) {
      // HUD TopBar
      TopBarView(
        state: topBarState,
        onQuestionTap: onQuestionTap,
        onNotificationTap: onNotificationTap
      )

      // Mongle Scene
      MongleSceneView(
        hasCurrentUserAnswered: hasCurrentUserAnswered,
        onViewAnswer: onPeerAnswerTap,
        onNudge: onPeerNudgeTap
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(MongleColor.background)
    .ignoresSafeArea(edges: .top)
  }
}

// MARK: - TopBar View (HUD 3단 구조)

struct TopBarView: View {
  let state: HomeTopBarState
  var onQuestionTap: () -> Void = { print("질문 카드 탭") }
  var onNotificationTap: () -> Void = { print("알림 탭") }
  
  var body: some View {
    VStack(spacing: 30) {
      // 1단: Streak | 그룹명 | 알림
      StatusHUDView(
        streakDays: state.streakDays,
        groupName: state.groupName,
        hasNotification: state.hasNotification,
        onNotificationTap: onNotificationTap
      )
      
      // 2단: 오늘의 질문 카드
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


// MARK: 누적 답변기록

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
    Text("\(days) Days")
      .font(.caption.bold())
      .foregroundColor(badgeColor)
      .padding(.all, 10)
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

// MARK: - 2단: 오늘의 질문 카드

private struct TodayQuestionCard: View {
  let question: TopBarQuestion
  var onTap: () -> Void
  
  @State private var isPressed = false
  
  var body: some View {
    Button { onTap() } label: {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 4) {
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

// MARK: - Preview
#Preview {
  HomeView()
}
