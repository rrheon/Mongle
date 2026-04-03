import SwiftUI
import ComposableArchitecture

// MARK: - Notification Permission Steps

extension GroupSelectView {

    // MARK: - Step: 알림 허용

    var notificationPermissionView: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.lg) {
            // 진행 표시
            HStack(spacing: MongleSpacing.xs) {
                Capsule().fill(MongleColor.moodCalm).frame(height: 4)
                Capsule().fill(MongleColor.moodCalm).frame(height: 4)
                Capsule().fill(MongleColor.borderWarm).frame(height: 4)
            }
            .padding(.bottom, MongleSpacing.sm)

            VStack(alignment: .leading, spacing: MongleSpacing.xs) {
                Text(L10n.tr("perm_notif_title"))
                    .font(MongleFont.heading2())
                    .foregroundColor(MongleColor.textPrimary)
                Text(L10n.tr("perm_notif_desc"))
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 0) {
                notifPermissionRow(icon: "bubble.left.fill", text: L10n.tr("perm_notif_answer"))
                Divider().padding(.leading, 44)
                notifPermissionRow(icon: "hand.tap.fill", text: L10n.tr("perm_notif_nudge"))
                Divider().padding(.leading, 44)
                notifPermissionRow(icon: "questionmark.circle.fill", text: L10n.tr("perm_notif_question"))
            }
            .monglePanel(
                background: MongleColor.cardBackground,
                cornerRadius: MongleRadius.large,
                borderColor: MongleColor.borderWarm,
                shadowOpacity: 0
            )
        }
    }

    private func notifPermissionRow(icon: String, text: String) -> some View {
        HStack(spacing: MongleSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(MongleColor.primary)
                .frame(width: 28)
            Text(text)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textPrimary)
            Spacer()
        }
        .padding(MongleSpacing.md)
    }

    // MARK: - Step: 방해 금지 시간

    var quietHoursPermissionView: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.lg) {
            // 진행 표시
            HStack(spacing: MongleSpacing.xs) {
                Capsule().fill(MongleColor.moodCalm).frame(height: 4)
                Capsule().fill(MongleColor.moodCalm).frame(height: 4)
                Capsule().fill(MongleColor.moodCalm).frame(height: 4)
            }
            .padding(.bottom, MongleSpacing.sm)

            VStack(alignment: .leading, spacing: MongleSpacing.xs) {
                Text(L10n.tr("perm_dnd_title"))
                    .font(MongleFont.heading2())
                    .foregroundColor(MongleColor.textPrimary)
                Text(L10n.tr("perm_dnd_desc"))
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: MongleSpacing.md) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 24))
                    .foregroundColor(MongleColor.primary)
                    .frame(width: 44, height: 44)
                    .background(MongleColor.primaryLight)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("perm_dnd_time"))
                        .font(MongleFont.body2Bold())
                        .foregroundColor(MongleColor.textPrimary)
                    Text(L10n.tr("perm_dnd_hint"))
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textSecondary)
                }

                Spacer()
            }
            .padding(MongleSpacing.md)
            .monglePanel(
                background: MongleColor.cardBackground,
                cornerRadius: MongleRadius.large,
                borderColor: MongleColor.borderWarm,
                shadowOpacity: 0
            )
        }
    }
}
