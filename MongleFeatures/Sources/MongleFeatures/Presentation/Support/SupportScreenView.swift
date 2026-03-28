import SwiftUI
import ComposableArchitecture
import Domain

/// Wrapper around support screens for navigation
public struct SupportScreenView: View {
    enum Destination: Equatable {
        case historyCalendar
    }

    @Bindable var store: StoreOf<SupportScreenFeature>

    public init(store: StoreOf<SupportScreenFeature>) {
        self.store = store
    }

    @ViewBuilder
    public var body: some View {
        switch store.destination {
        case .historyCalendar:
            HistoryCalendarView(store: store.scope(state: \.historyCalendar, action: \.historyCalendar))
        }
    }
}
