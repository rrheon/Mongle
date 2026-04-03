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
        .overlay {
            if store.showLogoutConfirm {
                MonglePopupView(
                    title: L10n.tr("settings_logout"),
                    description: L10n.tr("settings_logout_confirm"),
                    primaryLabel: L10n.tr("settings_logout"),
                    secondaryLabel: L10n.tr("common_cancel"),
                    onPrimary: { store.send(.logoutConfirmed) },
                    onSecondary: { store.send(.alertDismissed) }
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: store.showLogoutConfirm)
            }
            if store.showDeleteConfirm {
                MonglePopupView(
                    title: L10n.tr("settings_delete_account"),
                    description: L10n.tr("settings_delete_confirm"),
                    primaryLabel: L10n.tr("settings_delete_btn"),
                    secondaryLabel: L10n.tr("common_cancel"),
                    isDestructive: true,
                    onPrimary: { store.send(.deleteAccountConfirmed) },
                    onSecondary: { store.send(.alertDismissed) }
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: store.showDeleteConfirm)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        MongleNavigationHeader(title: L10n.tr("settings_account")) {
            MongleBackButton { store.send(.backTapped) }
        } right: {
            EmptyView()
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            Text(L10n.tr("settings_account"))
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)
                .padding(.horizontal, MongleSpacing.xxs)

            VStack(spacing: 0) {
                accountRow(
                    icon: "arrow.right.square.fill",
                    iconColor: MongleColor.bgMintLight,
                    iconBackground: MongleColor.primaryLight,
                    title: L10n.tr("settings_logout"),
                    subtitle: L10n.tr("settings_logout_desc")
                ) {
                    store.send(.logoutTapped)
                }
              
              accountRow(
                  icon: "trash.fill",
                  iconColor: MongleColor.bgMintLight,
                  iconBackground: MongleColor.primaryLight,
                  title: L10n.tr("settings_delete_account"),
                  subtitle: L10n.tr("settings_delete_account_desc")
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
