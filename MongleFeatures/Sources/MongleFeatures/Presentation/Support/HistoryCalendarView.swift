import SwiftUI
import ComposableArchitecture

public struct HistoryCalendarView: View {
    @Bindable var store: StoreOf<HistoryCalendarFeature>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    public init(store: StoreOf<HistoryCalendarFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MongleSpacing.md) {
                sectionTitle("감정이 남아 있는 날짜", subtitle: "달력에서 선택하면 그날의 기분을 다시 볼 수 있어요")

                monthNavigation
                calendarGrid

                selectedDatePanel

                HStack(spacing: MongleSpacing.xs) {
                    invitePill("야간 차단")
                    invitePill("개별 토글")
                }
            }
            .padding(MongleSpacing.md)
            .padding(.bottom, MongleSpacing.xl)
        }
        .background(MongleColor.background)
        .navigationTitle("히스토리 달력")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.send(.closeTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(MongleColor.textPrimary)
                }
                .buttonStyle(MongleScaleButtonStyle())
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { store.send(.onAppear) }
        .alert(
            L10n.tr("error_unknown"),
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.send(.dismissError) } }
            ),
            actions: {
                Button(L10n.tr("common_confirm")) { store.send(.dismissError) }
            },
            message: { Text(store.errorMessage ?? "") }
        )
    }

    // MARK: - Month Navigation

    private var monthNavigation: some View {
        HStack {
            Button { store.send(.previousMonthTapped) } label: {
                Image(systemName: "chevron.left")
            }
            .foregroundColor(MongleColor.textPrimary)

            Spacer()

            Text(monthTitle)
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)

            Spacer()

            Button { store.send(.nextMonthTapped) } label: {
                Image(systemName: "chevron.right")
            }
            .foregroundColor(MongleColor.textPrimary)
        }
        .padding(.horizontal, MongleSpacing.sm)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: MongleSpacing.sm) {
            ForEach([L10n.tr("calendar_day_sun"), L10n.tr("calendar_day_mon"), L10n.tr("calendar_day_tue"), L10n.tr("calendar_day_wed"), L10n.tr("calendar_day_thu"), L10n.tr("calendar_day_fri"), L10n.tr("calendar_day_sat")], id: \.self) { day in
                Text(day)
                    .font(MongleFont.captionBold())
                    .foregroundColor(day == L10n.tr("calendar_day_sun") ? MongleColor.error : (day == L10n.tr("calendar_day_sat") ? MongleColor.info : MongleColor.textSecondary))
                    .frame(maxWidth: .infinity)
            }

            ForEach(calendarDays, id: \.self) { date in
                Button { store.send(.dateSelected(date)) } label: {
                    VStack(spacing: 4) {
                        Text(dayText(for: date))
                            .font(MongleFont.body2())
                            .foregroundColor(textColor(for: date))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(isSelected(date) ? MongleColor.primary : .clear))

                        Circle()
                            .fill(colorForMoodID(store.moodCalendar[Calendar.current.startOfDay(for: date)])
                                .opacity(store.moodCalendar[Calendar.current.startOfDay(for: date)] == nil ? 0 : 1))
                            .frame(width: 8, height: 8)
                    }
                    .frame(height: 50)
                    .opacity(isCurrentMonth(date) ? 1 : 0.32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MongleSpacing.md)
        .monglePanel(background: MongleColor.cardBackground, cornerRadius: MongleRadius.large, borderColor: MongleColor.borderWarm, shadowOpacity: 0)
    }

    // MARK: - Selected Date Panel

    private var selectedDatePanel: some View {
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
        .monglePanel(background: MongleColor.cardBackground, cornerRadius: MongleRadius.large, borderColor: MongleColor.borderWarm, shadowOpacity: 0)
    }

    // MARK: - Helpers

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = .current; f.setLocalizedDateFormatFromTemplate("yyyyMMM"); return f
    }()

    private static let selectedDateFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = .current; f.setLocalizedDateFormatFromTemplate("MMMdEEEE"); return f
    }()

    private var monthTitle: String { Self.monthFormatter.string(from: store.currentMonth) }
    private var selectedDateTitle: String { Self.selectedDateFormatter.string(from: store.selectedDate) }

    private var selectedMoodLabel: String {
        let id = store.moodCalendar[Calendar.current.startOfDay(for: store.selectedDate)] ?? "happy"
        return moodName(for: id)
    }

    private var calendarDays: [Date] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: store.currentMonth)),
              let range = calendar.range(of: .day, in: .month, for: store.currentMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        var days: [Date] = []
        if firstWeekday > 1 {
            for offset in stride(from: firstWeekday - 1, through: 1, by: -1) {
                if let date = calendar.date(byAdding: .day, value: -offset, to: monthStart) { days.append(date) }
            }
        }
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) { days.append(date) }
        }
        while days.count % 7 != 0 || days.count < 35, let last = days.last,
              let next = calendar.date(byAdding: .day, value: 1, to: last) { days.append(next) }
        return days
    }

    private func dayText(for date: Date) -> String { String(Calendar.current.component(.day, from: date)) }
    private func isSelected(_ date: Date) -> Bool { Calendar.current.isDate(date, inSameDayAs: store.selectedDate) }
    private func isCurrentMonth(_ date: Date) -> Bool { Calendar.current.isDate(date, equalTo: store.currentMonth, toGranularity: .month) }

    private func textColor(for date: Date) -> Color {
        if isSelected(date) { return .white }
        if !isCurrentMonth(date) { return MongleColor.textHint }
        let weekday = Calendar.current.component(.weekday, from: date)
        if weekday == 1 { return MongleColor.error }
        if weekday == 7 { return MongleColor.info }
        return MongleColor.textPrimary
    }

    private func moodName(for id: String) -> String {
        switch id {
        case "happy": return L10n.tr("mood_happy"); case "calm": return L10n.tr("mood_calm"); case "loved": return L10n.tr("mood_loved")
        case "sad": return L10n.tr("mood_sad"); case "tired": return L10n.tr("mood_tired"); case "excited": return L10n.tr("mood_excited")
        case "anxious": return L10n.tr("mood_anxious"); default: return L10n.tr("mood_happy")
        }
    }

    private func colorForMoodID(_ id: String?) -> Color {
        switch id {
        case "happy": return MongleColor.moodHappy; case "calm": return MongleColor.moodCalm
        case "loved": return MongleColor.moodLoved; case "sad": return MongleColor.moodSad
        case "tired": return MongleColor.moodTired; case "excited": return MongleColor.moodExcited
        case "anxious": return MongleColor.moodAnxious; default: return .clear
        }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(MongleFont.body1Bold()).foregroundColor(MongleColor.textPrimary)
            Text(subtitle).font(MongleFont.caption()).foregroundColor(MongleColor.textSecondary)
        }
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
}
