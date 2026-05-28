//
//  HomeViewV2.swift
//  MongleFeatures
//
//  Created for MG-150 — Home v2 디자인 적용.
//
//  HomeView 의 v2 디자인 변형. State/Action 시그니처는 HomeView 와 완전히 동일하므로
//  MainTabView 의 매핑부 변경은 호출 대상 한 줄(HomeView → HomeViewV2)만으로 끝난다.
//  HomeFeature/Domain 은 손대지 않는다.
//

import SwiftUI
import Domain

// MARK: - Main View

struct HomeViewV2: View, Equatable {
    let topBarState: HomeTopBarState
    let hasCurrentUserAnswered: Bool
    let hasCurrentUserSkipped: Bool
    let members: [MongleMember]
    var currentUserName: String?
    var actions: HomeViewActions
    var showNotificationPermission: Bool = false

    @State private var showGroupDropdown = false

    // HomeView 와 동일한 equality — 클로저는 비교 제외, members 는 element-wise.
    static func == (lhs: HomeViewV2, rhs: HomeViewV2) -> Bool {
        guard lhs.topBarState == rhs.topBarState,
              lhs.hasCurrentUserAnswered == rhs.hasCurrentUserAnswered,
              lhs.hasCurrentUserSkipped == rhs.hasCurrentUserSkipped,
              lhs.currentUserName == rhs.currentUserName,
              lhs.showNotificationPermission == rhs.showNotificationPermission,
              lhs.members.count == rhs.members.count
        else { return false }
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
            V2CozyHomeBackground()

            VStack(spacing: 0) {
                HomeTopBarV2(
                    state: topBarState,
                    showGroupDropdown: $showGroupDropdown,
                    onNotificationTap: actions.onNotificationTap,
                    onHeartsTap: actions.onHeartsTap
                )

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
                // MG-150 — 하단 질문카드 + v2 탭바 영역만큼 보행 공간을 줄여
                // 캐릭터가 카드/탭바 뒤로 들어가지 않도록 제한.
                // (질문카드 ≈ 200pt + 탭바 ≈ 100pt; GeometryReader 가 줄어든 frame 을
                //  받아 wallPadding 안에서 보행)
                .padding(.bottom, topBarState.todayQuestion != nil ? 300 : 100)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .top)

            // 하단 고정 질문 카드 — v2 디자인은 질문 카드를 화면 하단에 배치한다.
            if let question = topBarState.todayQuestion {
                HomeQuestionCardV2(
                    question: question,
                    hasAnswered: hasCurrentUserAnswered,
                    hasSkipped: hasCurrentUserSkipped,
                    onTap: actions.onQuestionTap
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }

            // 그룹 드롭다운 — 헤더 아래 오버레이. 기존 동작 유지.
            if showGroupDropdown {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.15)) { showGroupDropdown = false } }

                HomeGroupDropdownV2(
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

// MARK: - V2 Top Bar (Home 전용)

/// v2 톤 헤더. V2HeaderTopBar 의 비주얼을 가져오되, 더미 데이터/절대 패딩 대신
/// HomeTopBarState 바인딩 + 액션 콜백 + 스케일 버튼 인터랙션을 부착한다.
/// HeartCallout popover 는 v2 디자인에 없으므로 제거 — 하트 칩 탭은 기존 delegate
/// 흐름(`heartsTapped → navigateToHeartsSystem`)을 그대로 따른다.
/// 스트릭 칩(streakDays)은 1차 PR 범위 외로 노출하지 않는다.
private struct HomeTopBarV2: View {
    let state: HomeTopBarState
    @Binding var showGroupDropdown: Bool
    var onNotificationTap: () -> Void
    var onHeartsTap: () -> Void

    private var ink: Color { V2Palette.ink }
    private var chipBg: Color { V2Palette.ink.opacity(0.08) }

    var body: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showGroupDropdown.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(state.groupName)
                        .font(V2Font.suit(16, .bold))
                        .foregroundStyle(ink)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ink)
                        .rotationEffect(.degrees(showGroupDropdown ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: showGroupDropdown)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 8) {
                Button(action: onHeartsTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(V2Palette.heartPink)
                        Text("\(state.hearts)")
                            .font(V2Font.suit(13, .bold))
                            .foregroundStyle(ink)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(chipBg, in: Capsule())
                }
                .buttonStyle(MongleScaleButtonStyle())

                Button(action: onNotificationTap) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(V2Palette.mutedSoft)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(chipBg, in: Capsule())
                        .overlay(alignment: .topTrailing) {
                            if state.hasNotification {
                                Circle()
                                    .fill(V2Palette.notif)
                                    .frame(width: 8, height: 8)
                                    .overlay(Circle().strokeBorder(.white, lineWidth: 1))
                                    .offset(x: -2, y: 2)
                            }
                        }
                }
                .buttonStyle(MongleScaleButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(V2Glass(cornerRadius: 24))
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }
}

// MARK: - V2 Question Card (하단 고정)

/// v2 질문 카드. V2QuestionCard 비주얼을 가져와 다국어/액션/answered·skipped 표기를 부착.
/// 카드 전체가 탭 영역이며, CTA 버튼은 시각 데코로 두고 onTap 은 questionTapped 동일.
private struct HomeQuestionCardV2: View {
    let question: TopBarQuestion
    let hasAnswered: Bool
    let hasSkipped: Bool
    let onTap: () -> Void

    private var statusLabel: String {
        if hasAnswered { return L10n.tr("home_answer_complete") }
        if hasSkipped  { return L10n.tr("home_skipped_label") }
        return L10n.tr("home_today_question")
    }

    private var statusColor: Color {
        if hasAnswered { return V2Palette.mintInk }
        if hasSkipped  { return V2Palette.muted }
        return V2Palette.coral
    }

    private var ctaLabel: String {
        hasAnswered ? L10n.tr("home_answer_complete") : L10n.tr("home_answer_btn")
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Circle().fill(statusColor).frame(width: 6, height: 6)
                    Text(statusLabel)
                        .font(V2Font.suit(12, .bold))
                        .foregroundStyle(statusColor)
                        .tracking(0.3)
                    if hasAnswered {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(V2Palette.mintInk)
                    }
                }

                Text(question.text)
                    .font(V2Font.suit(20, .bold))
                    .foregroundStyle(V2Palette.ink)
                    .lineSpacing(4)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)

                HStack(spacing: 6) {
                    Text(ctaLabel)
                        .font(V2Font.suit(15, .bold))
                        .foregroundStyle(V2Palette.ink)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(V2Palette.ink)
                }
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(V2Palette.mint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.82))
                    )
                    .shadow(color: .black.opacity(0.10), radius: 15, x: 0, y: 8)
            }
            .padding(.horizontal, 16)
        }
        .buttonStyle(MongleScaleButtonStyle())
        // MG-150 — v2 탭바(높이 64 + bottom padding 8) 위로 카드를 띄운다.
        // 시스템 탭바가 hidden 이라도 NavigationStack 의 safeArea bottom 처리에
        // 따라 정확한 inset 이 달라질 수 있어 여유 있게 잡는다.
        .padding(.bottom, 96)
    }
}

// MARK: - V2 Group Dropdown

/// 기존 GroupDropdownView 와 동일 구조 — 비주얼만 v2 톤(SUIT 폰트 + V2Palette)으로.
private struct HomeGroupDropdownV2: View {
    let families: [MongleGroup]
    let currentGroupId: UUID?
    var onGroupSelected: (MongleGroup) -> Void
    var onNavigateToGroupSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ForEach(families, id: \.id) { family in
                    Button { onGroupSelected(family) } label: {
                        HStack {
                            Text(family.name)
                                .font(V2Font.suit(15, .medium))
                                .foregroundStyle(
                                    family.id == currentGroupId
                                        ? V2Palette.mintInk
                                        : V2Palette.ink
                                )
                            Spacer()
                            if family.id == currentGroupId {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(V2Palette.mintInk)
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    if family.id != families.last?.id {
                        Divider().padding(.horizontal, 16)
                    }
                }

                if !families.isEmpty { Divider() }

                Button { onNavigateToGroupSelect() } label: {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(V2Palette.mutedSoft)
                        Text(L10n.tr("home_group_manage"))
                            .font(V2Font.suit(15, .medium))
                            .foregroundStyle(V2Palette.mutedSoft)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(V2Palette.mutedSoft)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: MongleRadius.large, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
            )
            .containerRelativeFrame(.horizontal) { width, _ in width / 2 }
            .padding(.leading, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Preview

#Preview {
    HomeViewV2()
}
