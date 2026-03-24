//
//  Untitled.swift
//  FTFeatures
//
//  Created by 최용헌 on 1/22/26.
//

import SwiftUI
import Domain

// MARK: - TopBar State Models

struct HomeTopBarState {
  var streakDays: Int
  var groupName: String
  var hasNotification: Bool
  var hearts: Int
  var todayQuestion: TopBarQuestion?
  var allFamilies: [MongleGroup]

  init(
    streakDays: Int,
    groupName: String,
    hasNotification: Bool,
    hearts: Int,
    todayQuestion: TopBarQuestion? = nil,
    allFamilies: [MongleGroup] = []
  ) {
    self.streakDays = streakDays
    self.groupName = groupName
    self.hasNotification = hasNotification
    self.hearts = hearts
    self.todayQuestion = todayQuestion
    self.allFamilies = allFamilies
  }

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

// MARK: - HomeView Actions

struct HomeViewActions {
    var onQuestionTap: () -> Void = {}
    var onNotificationTap: () -> Void = {}
    var onHeartsTap: () -> Void = {}
    var onPeerAnswerTap: (String) -> Void = { _ in }
    var onPeerNudgeTap: (String) -> Void = { _ in }
    var onMyMonggleTap: () -> Void = {}
    var onGroupSelected: (MongleGroup) -> Void = { _ in }
    var onNavigateToGroupSelect: () -> Void = {}
}

// MARK: - Main View

struct HomeView: View {
    let topBarState: HomeTopBarState
    let hasCurrentUserAnswered: Bool
    let hasCurrentUserSkipped: Bool
    let members: [(name: String, color: Color, hasAnswered: Bool)]
    var currentUserName: String?
    var actions: HomeViewActions

    @State private var showGroupDropdown = false

    init(
        topBarState: HomeTopBarState = .preview,
        hasCurrentUserAnswered: Bool = false,
        hasCurrentUserSkipped: Bool = false,
        members: [(name: String, color: Color, hasAnswered: Bool)] = [],
        currentUserName: String? = nil,
        actions: HomeViewActions = HomeViewActions()
    ) {
        self.topBarState = topBarState
        self.hasCurrentUserAnswered = hasCurrentUserAnswered
        self.hasCurrentUserSkipped = hasCurrentUserSkipped
        self.members = members
        self.currentUserName = currentUserName
        self.actions = actions
    }

    var body: some View {
        ZStack(alignment: .top) {
            MongleBackground()

            VStack(spacing: 0) {
                // TopBar
                TopBarView(
                    state: topBarState,
                    showGroupDropdown: $showGroupDropdown,
                    onQuestionTap: actions.onQuestionTap,
                    onNotificationTap: actions.onNotificationTap,
                    onHeartsTap: actions.onHeartsTap
                )

                // Mongle Scene
                MongleSceneView(
                    hasCurrentUserAnswered: hasCurrentUserAnswered,
                    hasCurrentUserSkipped: hasCurrentUserSkipped,
                    members: members,
                    currentUserName: currentUserName,
                    onViewAnswer: actions.onPeerAnswerTap,
                    onNudge: actions.onPeerNudgeTap,
                    onSelfTap: actions.onMyMonggleTap
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .top)

            // 그룹 드롭다운 오버레이 (헤더 바로 아래, safe area 무시)
            if showGroupDropdown {
                // 반투명 배경 (터치 시 닫기)
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.15)) { showGroupDropdown = false } }

                GroupDropdownView(
                    families: topBarState.allFamilies,
                    currentGroupName: topBarState.groupName,
                    onGroupSelected: { family in
                        withAnimation(.easeInOut(duration: 0.15)) { showGroupDropdown = false }
                        actions.onGroupSelected(family)
                    },
                    onNavigateToGroupSelect: {
                        withAnimation(.easeInOut(duration: 0.15)) { showGroupDropdown = false }
                        actions.onNavigateToGroupSelect()
                    }
                )
                // ZStack이 safe area를 포함하도록 ignoresSafeArea 적용 후
                // 헤더 높이(safeArea 포함 116pt)만큼 top padding
                .ignoresSafeArea(edges: .top)
                .padding(.top, 116)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - TopBar View

struct TopBarView: View {
  let state: HomeTopBarState
  @Binding var showGroupDropdown: Bool
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
      } else if isBeforeNoon {
        // 오전에는 비활성 안내 카드 표시 (탭 불가)
        let placeholder = TopBarQuestion(
          id: UUID(),
          text: "오후 12시에 다시 질문을 받을 수 있어요",
          isAnswered: false
        )
        TodayQuestionCard(question: placeholder, onTap: nil)
          .padding(.horizontal, 20)
          .padding(.top, 12)
          .padding(.bottom, 8)
      }
    }
  }

  private var isBeforeNoon: Bool {
    let cal = Calendar.current
    let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    return Date() < noon
  }

  private var headerView: some View {
    HStack(spacing: 12) {
      Button {
        withAnimation(.easeInOut(duration: 0.2)) {
          showGroupDropdown.toggle()
        }
      } label: {
        HStack(spacing: 4) {
          Text(state.groupName)
            .font(MongleFont.heading3().weight(.bold))
            .foregroundColor(MongleColor.textPrimary)
          Image(systemName: "chevron.down")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(MongleColor.textSecondary)
            .rotationEffect(.degrees(showGroupDropdown ? 180 : 0))
            .animation(.easeInOut(duration: 0.2), value: showGroupDropdown)
        }
      }
      .buttonStyle(.plain)

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

  @State private var showCallout = false

  var body: some View {
    Button { showCallout.toggle() } label: {
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
    .popover(isPresented: $showCallout, arrowEdge: .top) {
      HeartCalloutView(hearts: hearts)
        .presentationCompactAdaptation(.popover)
    }
  }
}

// MARK: 하트 설명 카드 (버튼 아래 작은 팝오버)

private struct HeartCalloutView: View {
  let hearts: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 6) {
        Image(systemName: "heart.fill")
          .foregroundColor(MongleColor.heartRed)
          .font(.system(size: 13))
        Text("현재 보유 \(hearts)개")
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.heartRed)
      }

      Divider()

      heartRow(icon: "arrow.clockwise.circle.fill", color: MongleColor.secondary, text: "질문 다시받기", cost: "1개")
      heartRow(icon: "pencil.circle.fill", color: MongleColor.accentOrange, text: "나만의 질문 작성", cost: "3개")
      heartRow(icon: "megaphone.fill", color: MongleColor.heartRed, text: "재촉하기", cost: "1개")

      Divider()

      HStack(spacing: 4) {
        Image(systemName: "sun.rise.fill")
          .foregroundColor(MongleColor.primary)
          .font(.system(size: 11))
        Text("매일 오전 +1 · 답변 완료 +3")
          .font(MongleFont.caption())
          .foregroundColor(MongleColor.textSecondary)
      }
    }
    .padding(14)
    .frame(width: 220)
  }

  private func heartRow(icon: String, color: Color, text: String, cost: String) -> some View {
    HStack {
      Image(systemName: icon)
        .foregroundColor(color)
        .font(.system(size: 12))
        .frame(width: 18)
      Text(text)
        .font(MongleFont.caption())
        .foregroundColor(MongleColor.textPrimary)
      Spacer()
      Text("하트 \(cost)")
        .font(MongleFont.caption())
        .foregroundColor(MongleColor.heartRed)
    }
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
    var onTap: (() -> Void)?  // nil이면 비활성 카드 (탭 이벤트 없음)

    var body: some View {
        let cardContent = HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                // 타이틀 및 완료 체크마크
                headerView

                // 질문 텍스트
                Text(question.text)
                    .font(.subheadline.bold())
                    .foregroundColor(onTap != nil ? .primary : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(cardBackground)

        if let onTap = onTap {
            Button(action: onTap) { cardContent }
                .buttonStyle(CardButtonStyle())
        } else {
            cardContent
        }
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

// MARK: - Group Dropdown View

private struct GroupDropdownView: View {
  let families: [MongleGroup]
  let currentGroupName: String
  var onGroupSelected: (MongleGroup) -> Void
  var onNavigateToGroupSelect: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 0) {
        // 그룹 목록
        ForEach(families, id: \.id) { family in
          Button {
            onGroupSelected(family)
          } label: {
            HStack {
              Text(family.name)
                .font(MongleFont.body1())
                .foregroundColor(
                  family.name == currentGroupName
                    ? MongleColor.primary
                    : MongleColor.textPrimary
                )
              Spacer()
              if family.name == currentGroupName {
                Image(systemName: "checkmark")
                  .font(.system(size: 13, weight: .semibold))
                  .foregroundColor(MongleColor.primary)
              }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
          }
          .buttonStyle(.plain)

          if family.id != families.last?.id {
            Divider()
              .padding(.horizontal, 16)
          }
        }

        if !families.isEmpty {
          Divider()
        }

        // 그룹선택화면 이동 버튼
        Button {
          onNavigateToGroupSelect()
        } label: {
          HStack {
            Image(systemName: "person.2.fill")
              .font(.system(size: 13))
              .foregroundColor(MongleColor.textSecondary)
            Text("그룹 관리")
              .font(MongleFont.body1())
              .foregroundColor(MongleColor.textSecondary)
            Spacer()
            Image(systemName: "chevron.right")
              .font(.system(size: 12))
              .foregroundColor(MongleColor.textSecondary)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
      }
      .background(Color.white)
      .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
      .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
      .frame(width: UIScreen.main.bounds.width / 2)
      .padding(.leading, 16)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

// MARK: - Preview
#Preview {
  HomeView()
}
