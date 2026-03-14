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
  var hearts: Int
  var todayQuestion: TopBarQuestion?

  static let preview = HomeTopBarState(
    streakDays: 5,
    groupName: "Kim Family",
    hasNotification: true,
    hearts: 5,
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
    ZStack {
      MongleBackground()

      VStack(spacing: 0) {
        // TopBar
        TopBarView(
          state: topBarState,
          onQuestionTap: onQuestionTap,
          onNotificationTap: onNotificationTap,
          onHeartsTap: onHeartsTap
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
      .ignoresSafeArea(edges: .top)
    }
  }
}

// MARK: - TopBar View

struct TopBarView: View {
  let state: HomeTopBarState
  var onQuestionTap: () -> Void = { print("질문 카드 탭") }
  var onNotificationTap: () -> Void = { print("알림 탭") }
  var onHeartsTap: () -> Void = {}

  var body: some View {
    VStack(spacing: 0) {
      // 1단: 통합 헤더
      headerView

      // 2단: 오늘의 질문 카드
      if let question = state.todayQuestion {
        TodayQuestionCard(question: question, onTap: onQuestionTap)
          .padding(.horizontal, 20)
          .padding(.top, 12)
          .padding(.bottom, 8)
      }
    }
  }

  private var headerView: some View {
    HStack(spacing: 12) {
      Text(state.groupName)
        .font(MongleFont.heading3().weight(.bold))
        .foregroundColor(MongleColor.textPrimary)

      Spacer()

      HeartsButtonView(hearts: state.hearts, onTap: onHeartsTap)
      NotificationButtonView(hasNotification: state.hasNotification, onTap: onNotificationTap)
    }
    .frame(height: 56)
    .padding(.horizontal, 20)
    .padding(.top, 60)
    .background(Color.white.ignoresSafeArea(edges: .top))
  }
}

// MARK: 하트버튼

private struct HeartsButtonView: View {
  let hearts: Int
  var onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 4) {
        Image(systemName: "heart.fill")
          .font(.system(size: 13))
          .foregroundColor(MongleColor.heartRed)
        Text("\(hearts)")
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.textPrimary)
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 10)
      .background(MongleColor.heartRedLight)
      .clipShape(Capsule())
    }
    .buttonStyle(.plain)
  }
}

// MARK: 알림버튼

private struct NotificationButtonView: View {
  let hasNotification: Bool
  var onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      ZStack(alignment: .topTrailing) {
        Image(systemName: "bell.fill")
          .font(.system(size: 13))
          .foregroundColor(MongleColor.primary)
          .padding(.vertical, 6)
          .padding(.horizontal, 10)
          .background(MongleColor.primaryLight)
          .clipShape(Capsule())

        if hasNotification {
          Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)
            .offset(x: -2, y: 2)
        }
      }
    }
    .buttonStyle(.plain)
  }
}

// MARK: - 오늘의 질문 카드

private struct TodayQuestionCard: View {
    let question: TopBarQuestion
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    // 타이틀 및 완료 체크마크
                    headerView
                    
                    // 질문 텍스트
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
            .background(cardBackground)
        }
        .buttonStyle(CardButtonStyle()) // 커스텀 스타일 적용
    }
    
    // 헤더뷰
    private var headerView: some View {
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
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white.opacity(0.85))
            .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
    }
  
  // 오늘의 질문 카드 스타일
  private struct CardButtonStyle: ButtonStyle {
      func makeBody(configuration: Configuration) -> some View {
          configuration.label
              .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
              .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
      }
  }
}

// MARK: - Preview
#Preview {
  HomeView()
}
