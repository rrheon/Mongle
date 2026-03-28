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
                    title: "로그아웃",
                    description: "정말 로그아웃할까요?",
                    primaryLabel: "로그아웃",
                    secondaryLabel: "취소",
                    onPrimary: { store.send(.logoutConfirmed) },
                    onSecondary: { store.send(.alertDismissed) }
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: store.showLogoutConfirm)
            }
            if store.showDeleteConfirm {
                MonglePopupView(
                    title: "계정 탈퇴",
                    description: "탈퇴하면 모든 데이터가 삭제돼요.\n이 작업은 되돌릴 수 없어요.",
                    primaryLabel: "탈퇴하기",
                    secondaryLabel: "취소",
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
        MongleNavigationHeader(title: "계정 관리") {
            MongleBackButton { store.send(.backTapped) }
        } right: {
            EmptyView()
        }
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
                    iconColor: MongleColor.bgMintLight,
                    iconBackground: MongleColor.primaryLight,
                    title: "로그아웃",
                    subtitle: "기기에서 로그아웃해요"
                ) {
                    store.send(.logoutTapped)
                }
              
              accountRow(
                  icon: "trash.fill",
                  iconColor: MongleColor.bgMintLight,
                  iconBackground: MongleColor.primaryLight,
                  title: "계정 탈퇴",
                  subtitle: "모든 데이터가 삭제되며 복구할 수 없어요"
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
