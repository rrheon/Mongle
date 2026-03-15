import SwiftUI
import ComposableArchitecture

public struct SupportScreenView: View {
    @Bindable var store: StoreOf<SupportScreenFeature>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    public init(store: StoreOf<SupportScreenFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MongleSpacing.lg) {
                switch store.screen {
                case .heartsSystem:
                    heartsView
                case .historyCalendar:
                    historyCalendarView
                case .notificationSettings:
                    notificationSettingsView
                case .groupManagement:
                    groupManagementView
                case .moodHistory:
                    moodHistoryView
                }
            }
            .padding(MongleSpacing.md)
            .padding(.bottom, MongleSpacing.xl)
        }
        .background(MongleColor.background)
        .alert("그룹 나가기", isPresented: Binding(
            get: { store.showLeaveConfirm },
            set: { if !$0 { store.send(.leaveGroupAlertDismissed) } }
        )) {
            Button("나가기", role: .destructive) {
                store.send(.leaveGroupConfirmed)
            }
            Button("취소", role: .cancel) {
                store.send(.leaveGroupAlertDismissed)
            }
        } message: {
            Text("그룹을 나가면 모든 가족과의 답변 기록이 연결 해제됩니다.")
        }
        .alert(
            store.kickTargetMember.map { "\($0.name)님을 내보낼까요?" } ?? "멤버 내보내기",
            isPresented: Binding(
                get: { store.showKickConfirm },
                set: { if !$0 { store.send(.kickMemberCancelled) } }
            )
        ) {
            Button("내보내기", role: .destructive) {
                store.send(.kickMemberConfirmed)
            }
            Button("취소", role: .cancel) {
                store.send(.kickMemberCancelled)
            }
        } message: {
            Text("해당 멤버는 그룹에서 제외됩니다.")
        }
        .navigationTitle(store.screen.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.send(.closeTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(MongleColor.textPrimary)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { store.send(.onAppear) }
    }

    private var heartsView: some View {
        VStack(spacing: MongleSpacing.md) {
            infoStrip(
                icon: "heart.text.square.fill",
                title: "하트는 관계를 움직이는 작은 자원이에요",
                description: "재촉, 질문 교체 같은 행동에만 제한적으로 사용돼요."
            )

            VStack(alignment: .leading, spacing: MongleSpacing.md) {
                Text("하트 💗")
                    .font(MongleFont.heading2())
                    .foregroundColor(.white)

                Text("가족에게 마음을 더 전하고 싶을 때 쓰는 작은 응원이에요.")
                    .font(MongleFont.body2())
                    .foregroundColor(.white.opacity(0.88))
                    .lineSpacing(3)

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: MongleSpacing.xs) {
                        Text("\(store.heartBalance)")
                            .font(MongleFont.heading1())
                            .foregroundColor(.white)
                        Text("보유 중인 하트")
                            .font(MongleFont.body2())
                            .foregroundColor(.white.opacity(0.85))
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        ForEach(0..<store.heartBalance, id: \.self) { _ in
                            Image(systemName: "heart.fill")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MongleSpacing.xl)
            .background(
                LinearGradient(
                    colors: [MongleColor.heartPink, MongleColor.heartPinkLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.xl))
            .overlay(alignment: .topTrailing) {
                Text("오늘 기준")
                    .font(MongleFont.captionBold())
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, MongleSpacing.sm)
                    .padding(.vertical, MongleSpacing.xxs)
                    .background(.white.opacity(0.16))
                    .clipShape(Capsule())
                    .padding(MongleSpacing.md)
            }

            VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                sectionTitle("하트 얻는 방법", subtitle: "매일 쌓이는 하트 규칙")

                HStack(spacing: MongleSpacing.sm) {
                    miniHeartCard(title: "오늘 접속하기", subtitle: "매일 1회", value: "+1", tint: MongleColor.heartPastel)
                    miniHeartCard(title: "질문에 답변하기", subtitle: "답변 1회당", value: "+3", tint: MongleColor.heartPastelLight)
                }
            }

            VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                sectionTitle("하트 사용처", subtitle: "필요한 순간에만 선택적으로 써요")

                heartsSection(
                    items: [
                        ("답변 재촉하기", "미답변 멤버에게 알림 전송", "하트 1개"),
                        ("다른 질문 받기", "오늘 질문을 새 질문으로 교체", "하트 3개"),
                        ("강제 질문 넘기기", "미답변 인원 있어도 다음 질문으로", "하트 5개"),
                    ]
                )
            }

            infoStrip(
                icon: "sparkles",
                title: "하트는 아껴 쓰는 구조예요",
                description: "답변을 꾸준히 남길수록 더 안정적으로 모을 수 있어요."
            )
        }
    }

    private func miniHeartCard(title: String, subtitle: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(MongleColor.heartRed)
                Spacer()
                Text(value)
                    .font(MongleFont.captionBold())
                    .foregroundColor(MongleColor.heartRed)
            }

            Text(title)
                .font(MongleFont.body2Bold())
                .foregroundColor(MongleColor.textPrimary)

            Text(subtitle)
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MongleSpacing.md)
        .background(tint)
        .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
    }

    private func heartsSection(items: [(String, String, String)]) -> some View {
        VStack(spacing: MongleSpacing.sm) {
            ForEach(items, id: \.0) { item in
                HStack(spacing: MongleSpacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.0)
                            .font(MongleFont.body2Bold())
                            .foregroundColor(MongleColor.textPrimary)
                        Text(item.1)
                            .font(MongleFont.caption())
                            .foregroundColor(MongleColor.textSecondary)
                    }

                    Spacer()

                    Text(item.2)
                        .font(MongleFont.captionBold())
                        .foregroundColor(MongleColor.heartRed)
                        .padding(.horizontal, MongleSpacing.sm)
                        .padding(.vertical, MongleSpacing.xxs)
                        .background(MongleColor.heartRedLight)
                        .clipShape(Capsule())
                }
                .padding(MongleSpacing.md)
                .background(MongleColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: MongleRadius.large)
                        .stroke(MongleColor.borderWarm, lineWidth: 1)
                )
            }
        }
    }

    private var historyCalendarView: some View {
        VStack(spacing: MongleSpacing.md) {
            sectionTitle("감정이 남아 있는 날짜", subtitle: "달력에서 선택하면 그날의 기분을 다시 볼 수 있어요")

            HStack {
                Button {
                    store.send(.previousMonthTapped)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .foregroundColor(MongleColor.textPrimary)

                Spacer()

                Text(monthTitle)
                    .font(MongleFont.body1Bold())
                    .foregroundColor(MongleColor.textPrimary)

                Spacer()

                Button {
                    store.send(.nextMonthTapped)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(MongleColor.textPrimary)
            }
            .padding(.horizontal, MongleSpacing.sm)

            LazyVGrid(columns: columns, spacing: MongleSpacing.sm) {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                    Text(day)
                        .font(MongleFont.captionBold())
                        .foregroundColor(day == "일" ? MongleColor.error : (day == "토" ? MongleColor.info : MongleColor.textSecondary))
                        .frame(maxWidth: .infinity)
                }

                ForEach(calendarDays, id: \.self) { date in
                    Button {
                        store.send(.dateSelected(date))
                    } label: {
                        VStack(spacing: 4) {
                            Text(dayText(for: date))
                                .font(MongleFont.body2())
                                .foregroundColor(textColor(for: date))
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(isSelected(date) ? MongleColor.primary : .clear)
                                )

                            Circle()
                                .fill(colorForMoodID(store.moodCalendar[Calendar.current.startOfDay(for: date)]).opacity(store.moodCalendar[Calendar.current.startOfDay(for: date)] == nil ? 0 : 1))
                                .frame(width: 8, height: 8)
                        }
                        .frame(height: 50)
                        .opacity(isCurrentMonth(date) ? 1 : 0.32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(MongleSpacing.md)
            .background(MongleColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.large)
                    .stroke(MongleColor.borderWarm, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                Text("선택한 날짜")
                    .font(MongleFont.captionBold())
                    .foregroundColor(MongleColor.textSecondary)
                Text(selectedDateTitle)
                    .font(MongleFont.body2Bold())
                    .foregroundColor(MongleColor.primary)
                HStack(spacing: MongleSpacing.sm) {
                    Circle()
                        .fill(colorForMoodID(store.moodCalendar[Calendar.current.startOfDay(for: store.selectedDate)]))
                        .frame(width: 28, height: 28)
                    Text(selectedMoodLabel)
                        .font(MongleFont.body1Bold())
                        .foregroundColor(MongleColor.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MongleSpacing.md)
            .background(MongleColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.large)
                    .stroke(MongleColor.borderWarm, lineWidth: 1)
            )

            HStack(spacing: MongleSpacing.xs) {
                invitePill("야간 차단")
                invitePill("개별 토글")
            }
        }
    }

    private var notificationSettingsView: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.md) {
            infoStrip(
                icon: "bell.badge.fill",
                title: "받고 싶은 알림만 남겨두세요",
                description: "답변, 재촉, 시스템 알림을 상황에 맞게 조절할 수 있어요."
            )

            settingsSection(title: "답변 알림", items: Array(store.notificationItems.prefix(2)))
            settingsSection(title: "재촉 알림", items: Array(store.notificationItems.dropFirst(2).prefix(2)))
            settingsSection(title: "시스템 알림", items: Array(store.notificationItems.dropFirst(4)))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("방해 금지 시간")
                        .font(MongleFont.body2Bold())
                    Text(store.quietHours)
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(MongleColor.textHint)
            }
            .padding(MongleSpacing.md)
            .background(MongleColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.large)
                    .stroke(MongleColor.borderWarm, lineWidth: 1)
            )

            infoStrip(
                icon: "chart.line.uptrend.xyaxis",
                title: "감정 흐름을 길게 보는 화면이에요",
                description: "최근 기록이 쌓일수록 나의 패턴을 더 선명하게 확인할 수 있어요."
            )
        }
    }

    private func settingsSection(title: String, items: [SupportScreenFeature.State.ToggleItem]) -> some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            Text(title)
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)
                .padding(.horizontal, MongleSpacing.xxs)

            VStack(spacing: 0) {
                ForEach(items) { item in
                    HStack(spacing: MongleSpacing.md) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(MongleFont.body2Bold())
                                .foregroundColor(MongleColor.textPrimary)
                            Text(item.subtitle)
                                .font(MongleFont.caption())
                                .foregroundColor(MongleColor.textSecondary)
                        }
                        Spacer()
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { item.isOn },
                                set: { store.send(.toggleChanged(item.id, $0)) }
                            )
                        )
                        .labelsHidden()
                        .tint(MongleColor.primary)
                    }
                    .padding(MongleSpacing.md)

                    if item.id != items.last?.id {
                        Divider()
                    }
                }
            }
            .background(MongleColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.large)
                    .stroke(MongleColor.borderWarm, lineWidth: 1)
            )
        }
    }

    private var groupManagementView: some View {
        VStack(spacing: MongleSpacing.md) {
            VStack(alignment: .leading, spacing: MongleSpacing.md) {
                sectionTitle("그룹 정보", subtitle: "함께하고 있는 사람과 초대 코드를 확인해요")

                HStack(spacing: MongleSpacing.md) {
                    Circle()
                        .fill(MongleColor.primaryLight)
                        .frame(width: 56, height: 56)
                        .overlay(Image(systemName: "person.3.fill").foregroundColor(MongleColor.primary))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.groupName)
                            .font(MongleFont.heading3())
                            .foregroundColor(MongleColor.textPrimary)
                        Text("코드: \(store.inviteCode)")
                            .font(MongleFont.caption())
                            .foregroundColor(MongleColor.textSecondary)
                    }
                }

                MongleButtonSecondary("새 멤버 초대하기") {
                    store.send(.inviteTapped)
                }

                HStack(spacing: MongleSpacing.xs) {
                    invitePill("\(store.members.count)명 참여")
                    invitePill("초대 코드 활성")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MongleSpacing.md)
            .background(MongleColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.large)
                    .stroke(MongleColor.borderWarm, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                sectionTitle("멤버", subtitle: "현재 이 공간에 연결된 사람들")

                ForEach(Array(store.members.enumerated()), id: \.element.id) { index, member in
                    HStack(spacing: MongleSpacing.md) {
                        MongleMonggle(color: monggleColor(for: index), size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.name)
                                .font(MongleFont.body2Bold())
                                .foregroundColor(MongleColor.textPrimary)
                            if member.isOwner {
                                Text(member.subtitle)
                                    .font(MongleFont.captionBold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, MongleSpacing.xs)
                                    .padding(.vertical, 2)
                                    .background(MongleColor.primary)
                                    .clipShape(Capsule())
                            } else {
                                Text(member.subtitle)
                                    .font(MongleFont.caption())
                                    .foregroundColor(MongleColor.textSecondary)
                            }
                        }

                        Spacer()

                        if store.isCurrentUserOwner && !member.isOwner {
                            Button {
                                store.send(.kickMemberTapped(member))
                            } label: {
                                Text("내보내기")
                                    .font(MongleFont.captionBold())
                                    .foregroundColor(MongleColor.error)
                                    .padding(.horizontal, MongleSpacing.sm)
                                    .padding(.vertical, MongleSpacing.xxs)
                                    .background(MongleColor.error.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        } else if !member.isOwner {
                            Image(systemName: "ellipsis")
                                .foregroundColor(MongleColor.textHint)
                        }
                    }
                    .padding(MongleSpacing.md)
                    .background(MongleColor.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: MongleRadius.large)
                            .stroke(MongleColor.borderWarm, lineWidth: 1)
                    )
                }
            }

            MongleButtonSecondary("그룹 나가기") {
                store.send(.leaveGroupTapped)
            }

            infoStrip(
                icon: "person.crop.circle.badge.checkmark",
                title: "그룹 정보는 언제든 바뀔 수 있어요",
                description: "멤버를 초대해도 같은 공간에서 질문과 답변 흐름은 계속 이어져요."
            )
        }
    }

    private var moodHistoryView: some View {
        VStack(spacing: MongleSpacing.md) {
            VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                sectionTitle("이번 달 기분 요약", subtitle: "3월에 가장 자주 남긴 감정을 확인해요")

            HStack(alignment: .center, spacing: MongleSpacing.lg) {
                ZStack {
                    Circle()
                        .stroke(MongleColor.moodHappy.opacity(0.22), lineWidth: 16)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0.00, to: 0.35)
                        .stroke(MongleColor.moodHappy, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0.35, to: 0.60)
                        .stroke(MongleColor.moodCalm, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0.60, to: 0.75)
                        .stroke(MongleColor.moodExcited, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)
                }

                VStack(alignment: .leading, spacing: MongleSpacing.xs) {
                    legendRow(color: MongleColor.moodHappy, title: "기쁨", value: "35%")
                    legendRow(color: MongleColor.moodCalm, title: "평온", value: "25%")
                    legendRow(color: MongleColor.moodExcited, title: "설렘", value: "15%")
                    legendRow(color: MongleColor.moodLoved, title: "사랑", value: "12%")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MongleSpacing.md)
            .background(MongleColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.large)
                    .stroke(MongleColor.borderWarm, lineWidth: 1)
            )
            }

            VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                sectionTitle("기분 타임라인", subtitle: "최근 14일")

                HStack {
                    ForEach(0..<5, id: \.self) { index in
                        Spacer()
                        VStack(spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                MongleMonggle(color: monggleColor(for: index), size: 44)
                                let count = moodFrequency(for: index)
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 18, height: 18)
                                        .background(MongleColor.primary)
                                        .clipShape(Circle())
                                        .offset(x: 6, y: -6)
                                }
                            }
                            Text(monggleMoodLabel(for: index))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(MongleColor.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MongleSpacing.md)
            .background(MongleColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.large)
                    .stroke(MongleColor.borderWarm, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                sectionTitle("최근 기분 기록", subtitle: "날짜별로 남긴 감정")

                ForEach(store.moodRecords) { record in
                    HStack(spacing: MongleSpacing.md) {
                        MongleMonggle(color: monggleColorForLabel(moodName(for: record.mood)), size: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(moodName(for: record.mood))
                                .font(MongleFont.body2Bold())
                                .foregroundColor(colorForMoodID(record.mood))
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                .font(MongleFont.caption())
                                .foregroundColor(MongleColor.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    if record.id != store.moodRecords.last?.id {
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MongleSpacing.md)
            .background(MongleColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.large)
                    .stroke(MongleColor.borderWarm, lineWidth: 1)
            )
        }
    }

    private func monggleColor(for index: Int) -> Color {
        let colors: [Color] = [
            MongleColor.monggleYellow,
            MongleColor.monggleGreen,
            MongleColor.mongglePink,
            MongleColor.monggleBlue,
            MongleColor.monggleOrange
        ]
        return colors[index % colors.count]
    }

    private func monggleMoodLabel(for index: Int) -> String {
        ["기쁨", "평온", "사랑", "우울", "지침"][index % 5]
    }

    private func moodFrequency(for index: Int) -> Int {
        let moods = [["happy"], ["calm"], ["loved"], ["sad"], ["tired"]]
        let targets = moods[index % moods.count]
        return store.moodRecords.filter { targets.contains($0.mood) }.count
    }

    private func monggleColorForLabel(_ label: String) -> Color {
        switch label {
        case "기쁨": return MongleColor.monggleYellow
        case "평온": return MongleColor.monggleGreen
        case "사랑": return MongleColor.mongglePink
        case "우울": return MongleColor.monggleBlue
        default: return MongleColor.monggleOrange
        }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)
            Text(subtitle)
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textSecondary)
        }
    }

    private func infoStrip(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: MongleSpacing.sm) {
            Circle()
                .fill(MongleColor.primaryLight)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(MongleColor.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(MongleFont.body2Bold())
                    .foregroundColor(MongleColor.textPrimary)
                Text(description)
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textSecondary)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(MongleSpacing.md)
        .monglePanel(background: MongleColor.bgCreamy, cornerRadius: MongleRadius.large, shadowOpacity: 0.02)
    }

    private func invitePill(_ title: String) -> some View {
        Text(title)
            .font(MongleFont.captionBold())
            .foregroundColor(MongleColor.primaryDark)
            .padding(.horizontal, MongleSpacing.sm)
            .padding(.vertical, MongleSpacing.xxs)
            .background(MongleColor.primaryLight)
            .clipShape(Capsule())
    }

    private func legendRow(color: Color, title: String, value: String) -> some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title)
                .font(MongleFont.body2())
            Spacer()
            Text(value)
                .font(MongleFont.body2Bold())
                .foregroundColor(color)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: store.currentMonth)
    }

    private var selectedDateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: store.selectedDate)
    }

    private var selectedMoodLabel: String {
        let id = store.moodCalendar[Calendar.current.startOfDay(for: store.selectedDate)] ?? "happy"
        return moodName(for: id)
    }

    private var calendarDays: [Date] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: store.currentMonth)),
              let range = calendar.range(of: .day, in: .month, for: store.currentMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        var days: [Date] = []

        let leadingEmptyDays = firstWeekday - 1
        if leadingEmptyDays > 0 {
            for offset in stride(from: leadingEmptyDays, through: 1, by: -1) {
                if let date = calendar.date(byAdding: .day, value: -offset, to: monthStart) {
                    days.append(date)
                }
            }
        }

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }

        while days.count % 7 != 0 || days.count < 35, let last = days.last, let next = calendar.date(byAdding: .day, value: 1, to: last) {
            days.append(next)
        }

        return days
    }

    private func dayText(for date: Date) -> String {
        String(Calendar.current.component(.day, from: date))
    }

    private func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: store.selectedDate)
    }

    private func textColor(for date: Date) -> Color {
        if isSelected(date) {
            return .white
        }
        if !isCurrentMonth(date) {
            return MongleColor.textHint
        }
        let weekday = Calendar.current.component(.weekday, from: date)
        if weekday == 1 {
            return MongleColor.error
        }
        if weekday == 7 {
            return MongleColor.info
        }
        return MongleColor.textPrimary
    }

    private func moodName(for id: String) -> String {
        switch id {
        case "happy": return "기쁨"
        case "calm": return "평온"
        case "loved": return "사랑"
        case "sad": return "우울"
        case "tired": return "지침"
        case "excited": return "설렘"
        case "anxious": return "불안"
        default: return "기쁨"
        }
    }

    private func colorForMoodID(_ id: String?) -> Color {
        switch id {
        case "happy": return MongleColor.moodHappy
        case "calm": return MongleColor.moodCalm
        case "loved": return MongleColor.moodLoved
        case "sad": return MongleColor.moodSad
        case "tired": return MongleColor.moodTired
        case "excited": return MongleColor.moodExcited
        case "anxious": return MongleColor.moodAnxious
        default: return .clear
        }
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: store.currentMonth, toGranularity: .month)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}
