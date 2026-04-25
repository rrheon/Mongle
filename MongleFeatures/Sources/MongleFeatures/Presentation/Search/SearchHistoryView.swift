//
//  SearchHistoryView.swift
//  MongleFeatures
//

import SwiftUI
import ComposableArchitecture
import Domain

// MARK: - Search History View

public struct SearchHistoryView: View {
    @Bindable var store: StoreOf<SearchHistoryFeature>
    @FocusState private var isSearchFocused: Bool

    public init(store: StoreOf<SearchHistoryFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchHeader
            bodyContent
        }
        .background(MongleColor.background)
        .toolbarBackground(Color.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onTapGesture {
            isSearchFocused = false
        }
        .onAppear {
            store.send(.onAppear)
            isSearchFocused = true
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(MongleColor.textSecondary)

                TextField(L10n.tr("search_placeholder"), text: Binding(
                    get: { store.query },
                    set: { store.send(.queryChanged($0)) }
                ))
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textPrimary)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .submitLabel(.search)

                if !store.query.isEmpty {
                    Button {
                        store.send(.queryChanged(""))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(MongleColor.textHint)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Color(hex: "F0F0F0"))
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.medium))
        }
        .padding(.horizontal, MongleSpacing.md)
        .padding(.vertical, 10)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    }

    // MARK: - Body Content

    @ViewBuilder
    private var bodyContent: some View {
        if store.isLoading {
            Spacer()
            ProgressView().tint(MongleColor.primary)
            Spacer()
        } else if store.showMinLengthHint {
            emptyStateView(icon: nil, message: L10n.tr("search_min_length"))
        } else if store.query.trimmingCharacters(in: .whitespaces).count >= 2 && store.results.isEmpty {
            emptyStateView(icon: "🔍", message: L10n.tr("search_no_results", store.query.trimmingCharacters(in: .whitespaces)))
        } else if !store.results.isEmpty {
            resultsList
        } else {
            emptyStateView(icon: nil, message: L10n.tr("search_empty"))
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0, pinnedViews: []) {
                // Count label
                HStack {
                    Text(L10n.tr("search_result_count", store.resultCount))
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textHint)
                    Spacer()
                }
                .padding(.horizontal, MongleSpacing.md)
                .padding(.top, MongleSpacing.md)
                .padding(.bottom, MongleSpacing.sm)

                // Date-grouped results
                let grouped = Dictionary(grouping: store.results) { $0.date.dayKey }
                let sortedGroups = grouped.keys.sorted(by: >)
                let total = store.results.count
                let globalIndices: [String: Int] = {
                    var idx = 0
                    var dict: [String: Int] = [:]
                    for dayKey in sortedGroups {
                        for item in (grouped[dayKey] ?? []) {
                            dict[item.id] = idx
                            idx += 1
                        }
                    }
                    return dict
                }()

                ForEach(sortedGroups, id: \.self) { dayKey in
                    let items = grouped[dayKey] ?? []
                    if let firstItem = items.first {
                        // Date header
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                                .foregroundColor(MongleColor.textHint)
                            Text(firstItem.date.displayLabel)
                                .font(MongleFont.label())
                                .fontWeight(.semibold)
                                .foregroundColor(MongleColor.textHint)
                            Spacer()
                        }
                        .padding(.horizontal, MongleSpacing.md)
                        .padding(.bottom, MongleSpacing.xs)

                        // Cards for this date
                        ForEach(items) { result in
                            SearchResultCard(
                                result: result,
                                query: store.query.trimmingCharacters(in: .whitespaces)
                            )
                            .padding(.horizontal, MongleSpacing.md)
                            .padding(.bottom, MongleSpacing.xs)

                            if shouldShowAd(after: globalIndices[result.id] ?? 0, total: total) {
                                #if os(iOS)
                                AdBannerSection()
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, MongleSpacing.sm)
                                #endif
                            }
                        }

                        Spacer().frame(height: MongleSpacing.xxs)
                    }
                }

                Spacer().frame(height: MongleSpacing.xl)
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func shouldShowAd(after index: Int, total: Int) -> Bool {
        (index + 1) % 11 == 0 || index + 1 == total
    }

    // MARK: - Empty State

    private func emptyStateView(icon: String?, message: String) -> some View {
        VStack(spacing: 12) {
            if let icon {
                Text(icon).font(.system(size: 40))
            } else{
              MongleLogo(size: .large, type: .MongleLogo)
            }
            Text(message)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textHint)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search Result Card

private struct SearchResultCard: View {
    let result: SearchResultItem
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            // Question — 매칭 여부와 무관하게 항상 표시.
            // (HighlightedText 의 AttributedString 경로 이슈를 회피하기 위해 직접 Text 로 렌더링)
            Text(result.questionContent)
                .font(MongleFont.body2Bold())
                .foregroundColor(MongleColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if !result.matchedAnswers.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(result.matchedAnswers.prefix(3).enumerated()), id: \.element.id) { index, answer in
                        AnswerRow(answer: answer, query: query, colorIndex: colorIndexFromMoodId(answer.moodId))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MongleSpacing.md)
        .background(MongleColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
        .shadow(color: MongleColor.shadowBase.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Answer Row

private struct AnswerRow: View {
    let answer: HistoryQuestion.HistoryAnswerSummary
    let query: String
    let colorIndex: Int

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MiniMongleAvatar(colorIndex: colorIndex)
            VStack(alignment: .leading, spacing: 2) {
                HighlightedText(text: answer.content, query: query, baseFont: MongleFont.caption())
                    .foregroundColor(MongleColor.textSecondary)
                    .lineLimit(2)
                MemberBadge(name: answer.userName, colorIndex: colorIndex)
            }
        }
    }
}

// MARK: - Mini Mongle Avatar

private struct MiniMongleAvatar: View {
    let colorIndex: Int

    private static let colors: [Color] = [
        MongleColor.monggleGreen,
        MongleColor.monggleYellow,
        MongleColor.mongglePink,
        MongleColor.monggleBlue,
        MongleColor.monggleOrange
    ]

    var body: some View {
        let color = Self.colors[colorIndex % Self.colors.count]
        MongleMonggle(color: color, size: 32)
    }
}

// MARK: - Member Badge

private struct MemberBadge: View {
    let name: String
    let colorIndex: Int

    private static let bgColors: [Color] = [
        Color(hex: "E8F5EE"),
        Color(hex: "FFF8E1"),
        Color(hex: "FCE4EC"),
        Color(hex: "E3F2FD"),
        Color(hex: "FFF3E0")
    ]

    var body: some View {
        Text(name)
            .font(MongleFont.label())
            .foregroundColor(MongleColor.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Self.bgColors[colorIndex % Self.bgColors.count])
            .clipShape(Capsule())
    }
}

// MARK: - Highlighted Text

private struct HighlightedText: View {
    let text: String
    let query: String
    let baseFont: Font

    var body: some View {
        // 텍스트가 비어 있어도 부모 레이아웃이 무너지지 않도록 빈 Text 라도 항상 그린다.
        let normalizedText = text.precomposedStringWithCanonicalMapping
        let normalizedQuery = query.precomposedStringWithCanonicalMapping.lowercased()

        // query 가 비었거나 텍스트에 포함되지 않으면, 안정적인 일반 Text 로 그대로 노출.
        // (AttributedString 경로에서 발생할 수 있는 미묘한 렌더링 이슈를 회피)
        if normalizedQuery.isEmpty || !normalizedText.lowercased().contains(normalizedQuery) {
            Text(normalizedText).font(baseFont)
        } else {
            Text(buildAttributedString(normalizedText: normalizedText, lowerQuery: normalizedQuery))
        }
    }

    private func buildAttributedString(normalizedText: String, lowerQuery: String) -> AttributedString {
        var attributed = AttributedString(normalizedText)
        attributed.font = baseFont

        let lowerText = normalizedText.lowercased()
        var searchRange = lowerText.startIndex..<lowerText.endIndex

        while let range = lowerText.range(of: lowerQuery, range: searchRange) {
            let start = lowerText.distance(from: lowerText.startIndex, to: range.lowerBound)
            let length = lowerText.distance(from: range.lowerBound, to: range.upperBound)
            if let attrRange = Range(NSRange(location: start, length: length), in: attributed) {
                attributed[attrRange].foregroundColor = UIColor(hex: "56A96B")
                attributed[attrRange].font = baseFont.bold()
            }
            searchRange = range.upperBound..<lowerText.endIndex
        }
        return attributed
    }
}

// MARK: - Helpers

private func colorIndexFromMoodId(_ moodId: String?) -> Int {
    switch moodId {
    case "calm":   return 0
    case "happy":  return 1
    case "loved":  return 2
    case "sad":    return 3
    case "tired":  return 4
    default:       return 2
    }
}

private extension Date {
    var dayKey: TimeInterval {
        Calendar.current.startOfDay(for: self).timeIntervalSince1970
    }

    var displayLabel: String {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        let base = formatter.string(from: self)
        if cal.isDateInToday(self) {
            return "\(base) · 오늘"
        } else if cal.isDateInYesterday(self) {
            return "\(base) · 어제"
        }
        return base
    }
}

// UIColor hex init for AttributedString
private extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}
