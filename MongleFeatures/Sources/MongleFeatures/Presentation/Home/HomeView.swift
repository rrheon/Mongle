//
//  Untitled.swift
//  FTFeatures
//
//  Created by 최용헌 on 1/22/26.
//

import SwiftUI
import Domain

// MARK: - TopBar State Models

struct HomeTopBarState: Equatable {
  var streakDays: Int
  var groupName: String
  var groupId: UUID?
  var hasNotification: Bool
  var hearts: Int
  var todayQuestion: TopBarQuestion?
  var allFamilies: [MongleGroup]

  init(
    streakDays: Int,
    groupName: String,
    groupId: UUID? = nil,
    hasNotification: Bool,
    hearts: Int,
    todayQuestion: TopBarQuestion? = nil,
    allFamilies: [MongleGroup] = []
  ) {
    self.streakDays = streakDays
    self.groupName = groupName
    self.groupId = groupId
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

struct TopBarQuestion: Identifiable, Equatable {
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
    var onNotificationPermissionAllowed: () -> Void = {}
    var onNotificationPermissionSkipped: () -> Void = {}
    var onAnswerRequiredTap: (String) -> Void = { _ in }
    var onNudgeUnavailableTap: (String) -> Void = { _ in }
}

// MARK: - Main View

/// HomeView 가 EquatableView 로 wrapping 될 수 있도록 Equatable 채택.
/// SwiftUI 는 Equatable View 의 == 가 true 일 때 body 평가를 skip 한다.
/// 그 결과 부모(MainTabView) 의 무관한 상태 변화(예: TopBar dropdown 토글) 가
/// HomeView 본문 + MongleSceneView 까지 invalidate 시키는 비용을 차단한다.
/// 클로저 멤버(actions)는 비교에서 제외 — closure identity 가 매번 새로 생성되므로
/// 비교에 포함하면 항상 false 가 되어 skip 효과가 사라진다.
struct HomeView: View, Equatable {
    let topBarState: HomeTopBarState
    let hasCurrentUserAnswered: Bool
    let hasCurrentUserSkipped: Bool
    let members: [MongleMember]
    var currentUserName: String?
    var actions: HomeViewActions
    var showNotificationPermission: Bool = false

    @State private var showGroupDropdown = false

    static func == (lhs: HomeView, rhs: HomeView) -> Bool {
        guard lhs.topBarState == rhs.topBarState,
              lhs.hasCurrentUserAnswered == rhs.hasCurrentUserAnswered,
              lhs.hasCurrentUserSkipped == rhs.hasCurrentUserSkipped,
              lhs.currentUserName == rhs.currentUserName,
              lhs.showNotificationPermission == rhs.showNotificationPermission,
              lhs.members.count == rhs.members.count
        else { return false }
        // 튜플 배열은 Equatable 자동 합성이 안 되므로 element-wise 비교.
        // (Swift 의 tuple == 는 arity ≤ 6 + 모든 element Equatable 일 때 사용 가능)
        for (l, r) in zip(lhs.members, rhs.members) {
            if l.name != r.name || l.color != r.color || l.hasAnswered != r.hasAnswered || l.hasSkipped != r.hasSkipped {
                return false
            }
        }
        return true
    }

    init(
        topBarState: HomeTopBarState = .preview,
        hasCurrentUserAnswered: Bool = false,
        hasCurrentUserSkipped: Bool = false,
        members: [MongleMember] = [],
        currentUserName: String? = nil,
        actions: HomeViewActions = HomeViewActions(),
        showNotificationPermission: Bool = false
    ) {
        self.topBarState = topBarState
        self.hasCurrentUserAnswered = hasCurrentUserAnswered
        self.hasCurrentUserSkipped = hasCurrentUserSkipped
        self.members = members
        self.currentUserName = currentUserName
        self.actions = actions
        self.showNotificationPermission = showNotificationPermission
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
                    onSelfTap: actions.onMyMonggleTap,
                    onAnswerFirstToView: actions.onAnswerRequiredTap,
                    onAnswerFirstToNudge: actions.onNudgeUnavailableTap
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .top)

            // 그룹 드롭다운
            if showGroupDropdown {
                // 반투명 배경 (터치 시 닫기) — 드롭다운 아래 레이어
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.15)) { showGroupDropdown = false } }

                GroupDropdownView(
                    families: topBarState.allFamilies,
                    currentGroupId: topBarState.groupId,
                    onGroupSelected: { family in
                        withAnimation(.easeInOut(duration: 0.15)) { showGroupDropdown = false }
                        actions.onGroupSelected(family)
                    },
                    onNavigateToGroupSelect: {
                        withAnimation(.easeInOut(duration: 0.15)) { showGroupDropdown = false }
                        actions.onNavigateToGroupSelect()
                    }
                )
                .padding(.top, 116)
            }
        }
        .ignoresSafeArea(edges: .top)
        .overlay {
            if showNotificationPermission {
                MonglePopupView(
                    icon: .init(
                        systemName: "bell.fill",
                        foregroundColor: MongleColor.primary,
                        backgroundColor: MongleColor.primaryLight
                    ),
                    title: L10n.tr("perm_notif_title"),
                    description: L10n.tr("perm_notif_desc"),
                    primaryLabel: L10n.tr("perm_notif_allow"),
                    secondaryLabel: L10n.tr("perm_notif_later"),
                    onPrimary: { actions.onNotificationPermissionAllowed() },
                    onSecondary: { actions.onNotificationPermissionSkipped() }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
    }
}

// MARK: - TopBar View

struct TopBarView: View {
  let state: HomeTopBarState
  @Binding var showGroupDropdown: Bool
  var onQuestionTap: () -> Void = {}
  var onNotificationTap: () -> Void = {}
  var onHeartsTap: () -> Void = {}

  var body: some View {
    VStack(spacing: 0) {
      // 1단: 통합 헤더
      headerView

      // 2단: 오늘의 질문 카드
      // 서버 스케줄러가 KST 정오에 새 질문을 배정하므로, 클라이언트는
      // todayQuestion 이 있으면 그대로 노출한다.
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
      .background(MongleColor.bgNeutral)
      .clipShape(Capsule())
    }
    .buttonStyle(MongleScaleButtonStyle())
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
        Text(L10n.tr("home_heart_count", hearts))
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.heartRed)
      }

      Divider()

      heartRow(icon: "arrow.clockwise.circle.fill", color: MongleColor.secondary, text: L10n.tr("home_heart_replace"), cost: L10n.tr("heart_cost", 3))
      heartRow(icon: "pencil.circle.fill", color: MongleColor.accentOrange, text: L10n.tr("home_heart_write"), cost: L10n.tr("heart_cost", 3))
      heartRow(icon: "megaphone.fill", color: MongleColor.heartRed, text: L10n.tr("home_heart_nudge"), cost: L10n.tr("heart_cost", 1))

      Divider()

      HStack(spacing: 4) {
        Image(systemName: "sun.min.fill")
          .foregroundColor(MongleColor.primary)
          .font(.system(size: 11))
        Text(L10n.tr("home_heart_earn_rate"))
          .font(MongleFont.caption())
          .foregroundColor(MongleColor.textSecondary)
      }
    }
    .padding(14)
    .frame(width: 220)
    .background(Color.white)
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
      Text(cost)
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
          .background(MongleColor.bgNeutral)
          .clipShape(Capsule())

        if hasNotification {
          Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)
            .offset(x: -2, y: 2)
        }
      }
    }
    .buttonStyle(MongleScaleButtonStyle())
  }
}

// MARK: - 오늘의 질문 카드

private struct TodayQuestionCard: View {
    let question: TopBarQuestion
    var onTap: (() -> Void)?  // nil이면 비활성 카드 (탭 이벤트 없음)

    var body: some View {
        if let onTap = onTap {
            Button(action: onTap) { cardBody }
                .buttonStyle(MongleScaleButtonStyle())
        } else {
            cardBody
        }
    }

    private var cardBody: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(L10n.tr("home_today_question"))
                        .font(MongleFont.captionBold())
                        .foregroundColor(MongleColor.primary)
                    if question.isAnswered {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(MongleColor.primary)
                    }
                }

                Text(question.text)
                    .font(MongleFont.body1Bold())
                    .foregroundColor(onTap != nil ? MongleColor.textPrimary : MongleColor.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(MongleColor.textHint)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .monglePanel(background: Color.white.opacity(0.85), cornerRadius: 14, borderColor: .clear, shadowOpacity: 0.07)
    }
}

// MARK: - Group Dropdown View

private struct GroupDropdownView: View {
  let families: [MongleGroup]
  let currentGroupId: UUID?
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
                  family.id == currentGroupId
                    ? MongleColor.primary
                    : MongleColor.textPrimary
                )
              Spacer()
              if family.id == currentGroupId {
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
            Text(L10n.tr("home_group_manage"))
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
      .monglePanel(background: Color.white, cornerRadius: MongleRadius.large, borderColor: .clear, shadowOpacity: 0.12)
      .containerRelativeFrame(.horizontal) { width, _ in width / 2 }
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
