import SwiftUI
import ComposableArchitecture

public struct AccountManagementView: View {
    @Bindable var store: StoreOf<AccountManagementFeature>

    public init(store: StoreOf<AccountManagementFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: MongleSpacing.lg) {
                    accountSection
                    dangerSection
                }
                .padding(.horizontal, MongleSpacing.md)
                .padding(.top, MongleSpacing.md)
                .padding(.bottom, MongleSpacing.xl)
            }
            .background(MongleColor.background)
        }
        .toolbar(.hidden, for: .navigationBar)
        .mongleErrorToast(
            error: store.appError,
            onDismiss: { store.send(.dismissError) }
        )
        .alert("로그아웃", isPresented: Binding(
            get: { store.showLogoutConfirm },
            set: { _ in store.send(.alertDismissed) }
        )) {
            Button("로그아웃", role: .destructive) { store.send(.logoutConfirmed) }
            Button("취소", role: .cancel) { store.send(.alertDismissed) }
        } message: {
            Text("정말 로그아웃할까요?")
        }
        .alert("계정 탈퇴", isPresented: Binding(
            get: { store.showDeleteConfirm },
            set: { _ in store.send(.alertDismissed) }
        )) {
            Button("탈퇴하기", role: .destructive) { store.send(.deleteAccountConfirmed) }
            Button("취소", role: .cancel) { store.send(.alertDismissed) }
        } message: {
            Text("탈퇴하면 모든 데이터가 삭제돼요.\n이 작업은 되돌릴 수 없어요.")
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("계정 관리")
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)

            HStack {
                Button { store.send(.backTapped) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(MongleColor.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 8)
        .background(Color.white)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            Text("계정")
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)
                .padding(.horizontal, MongleSpacing.xxs)

            VStack(spacing: 0) {
                accountRow(
                    icon: "arrow.right.square.fill",
                    iconColor: MongleColor.primary,
                    iconBackground: MongleColor.primaryLight,
                    title: "로그아웃",
                    subtitle: "기기에서 로그아웃해요"
                ) {
                    store.send(.logoutTapped)
                }
            }
            .background(MongleColor.cardBackgroundSolid)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
        }
    }

    // MARK: - Danger Section

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            Text("위험 구역")
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.error)
                .padding(.horizontal, MongleSpacing.xxs)

            VStack(spacing: 0) {
                accountRow(
                    icon: "trash.fill",
                    iconColor: MongleColor.error,
                    iconBackground: MongleColor.bgErrorSoft,
                    title: "계정 탈퇴",
                    subtitle: "모든 데이터가 삭제되며 복구할 수 없어요",
                    titleColor: MongleColor.error
                ) {
                    store.send(.deleteAccountTapped)
                }
            }
            .background(MongleColor.cardBackgroundSolid)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
        }
    }

    // MARK: - Row Builder

    private func accountRow(
        icon: String,
        iconColor: Color,
        iconBackground: Color,
        title: String,
        subtitle: String,
        titleColor: Color = MongleColor.textPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: MongleSpacing.md) {
                RoundedRectangle(cornerRadius: MongleRadius.medium)
                    .fill(iconBackground)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(iconColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MongleFont.body1())
                        .foregroundColor(titleColor)
                    Text(subtitle)
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textHint)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MongleColor.textHint)
            }
            .padding(.horizontal, MongleSpacing.md)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
