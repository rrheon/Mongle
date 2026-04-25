import SwiftUI
import ComposableArchitecture

public struct MoodHistoryView: View {
    @Bindable var store: StoreOf<MoodHistoryFeature>

    public init(store: StoreOf<MoodHistoryFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MongleSpacing.md) {
                summarySection
                timelineSection
                recordsSection
            }
            .padding(MongleSpacing.md)
            .padding(.bottom, MongleSpacing.xl)
        }
        .background(MongleColor.background)
        .navigationTitle(L10n.tr("settings_mood_history"))
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
    }

    // MARK: - Summary (Pie Chart)

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            sectionTitle(L10n.tr("history_mood_summary"), subtitle: moodSummarySubtitle)

            let pieData = moodPieData
            if pieData.isEmpty {
                Text(L10n.tr("history_mood_empty"))
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textHint)
                    .frame(maxWidth: .infinity)
                    .padding(MongleSpacing.xl)
                    .background(MongleColor.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
                    .overlay(RoundedRectangle(cornerRadius: MongleRadius.large).stroke(MongleColor.borderWarm, lineWidth: 1))
            } else {
                HStack(alignment: .center, spacing: MongleSpacing.lg) {
                    ZStack {
                        Circle().stroke(Color.gray.opacity(0.1), lineWidth: 16).frame(width: 100, height: 100)
                        ForEach(pieData, id: \.from) { segment in
                            Circle()
                                .trim(from: segment.from, to: segment.to)
                                .stroke(segment.color, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 100, height: 100)
                        }
                    }
                    VStack(alignment: .leading, spacing: MongleSpacing.xs) {
                        ForEach(pieData.prefix(4), id: \.from) { segment in
                            legendRow(color: segment.color, title: segment.label, value: segment.percentage)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MongleSpacing.md)
                .background(MongleColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
                .overlay(RoundedRectangle(cornerRadius: MongleRadius.large).stroke(MongleColor.borderWarm, lineWidth: 1))
            }
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            sectionTitle(L10n.tr("history_mood_timeline"), subtitle: L10n.tr("history_recent_mood"))

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
        .monglePanel(background: MongleColor.cardBackground, cornerRadius: MongleRadius.large, borderColor: MongleColor.borderWarm, shadowOpacity: 0)
    }

    // MARK: - Records

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            sectionTitle(L10n.tr("history_mood_recent"), subtitle: L10n.tr("history_mood_by_date"))

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
        .monglePanel(background: MongleColor.cardBackground, cornerRadius: MongleRadius.large, borderColor: MongleColor.borderWarm, shadowOpacity: 0)
    }

    // MARK: - Helpers

    private static let moodSummaryFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = .current; f.setLocalizedDateFormatFromTemplate("MMM"); return f
    }()

    private var moodSummarySubtitle: String {
        "\(Self.moodSummaryFormatter.string(from: store.currentMonth))에 가장 자주 남긴 감정을 확인해요"
    }

    private func moodFrequency(for index: Int) -> Int {
        let moods = [["happy"], ["calm"], ["loved"], ["sad"], ["tired"]]
        return store.moodRecords.filter { moods[index % moods.count].contains($0.mood) }.count
    }

    private func monggleMoodLabel(for index: Int) -> String {
        [L10n.tr("mood_happy"), L10n.tr("mood_calm"), L10n.tr("mood_loved"), L10n.tr("mood_sad"), L10n.tr("mood_tired")][index % 5]
    }

    private func monggleColor(for index: Int) -> Color {
        [MongleColor.monggleYellow, MongleColor.monggleGreen, MongleColor.mongglePink,
         MongleColor.monggleBlue, MongleColor.monggleOrange][index % 5]
    }

    private func monggleColorForLabel(_ label: String) -> Color {
        switch label {
        case L10n.tr("mood_happy"): return MongleColor.monggleYellow
        case L10n.tr("mood_calm"): return MongleColor.monggleGreen
        case L10n.tr("mood_loved"): return MongleColor.mongglePink
        case L10n.tr("mood_sad"): return MongleColor.monggleBlue
        default: return MongleColor.monggleOrange
        }
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

    private func legendRow(color: Color, title: String, value: String) -> some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title).font(MongleFont.body2())
            Spacer()
            Text(value).font(MongleFont.body2Bold()).foregroundColor(color)
        }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(MongleFont.body1Bold()).foregroundColor(MongleColor.textPrimary)
            Text(subtitle).font(MongleFont.caption()).foregroundColor(MongleColor.textSecondary)
        }
    }

    private var moodPieData: [(from: Double, to: Double, color: Color, label: String, percentage: String)] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: store.currentMonth)
        let month = calendar.component(.month, from: store.currentMonth)
        var counts: [String: Int] = [:]
        for record in store.moodRecords {
            guard calendar.component(.year, from: record.date) == year,
                  calendar.component(.month, from: record.date) == month else { continue }
            counts[record.mood, default: 0] += 1
        }
        let total = counts.values.reduce(0, +)
        guard total > 0 else { return [] }
        let moodDefs: [(String, Color, String)] = [
            ("happy", MongleColor.moodHappy, L10n.tr("mood_happy")), ("calm", MongleColor.moodCalm, L10n.tr("mood_calm")),
            ("loved", MongleColor.moodLoved, L10n.tr("mood_loved")), ("sad", MongleColor.moodSad, L10n.tr("mood_sad")),
            ("tired", MongleColor.moodTired, L10n.tr("mood_tired")),
        ]
        let sorted = moodDefs.filter { (counts[$0.0] ?? 0) > 0 }.sorted { (counts[$0.0] ?? 0) > (counts[$1.0] ?? 0) }
        var result: [(from: Double, to: Double, color: Color, label: String, percentage: String)] = []
        var current = 0.0
        for (id, color, label) in sorted {
            let fraction = Double(counts[id] ?? 0) / Double(total)
            let to = current + fraction
            result.append((from: current, to: to, color: color, label: label, percentage: "\(Int((fraction * 100).rounded()))%"))
            current = to
        }
        return result
    }
}
