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
                Text("알림을 허용해 주세요 🔔")
                    .font(MongleFont.heading2())
                    .foregroundColor(MongleColor.textPrimary)
                Text("가족의 소식을 놓치지 않을 수 있어요")
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 0) {
                notifPermissionRow(icon: "bubble.left.fill", text: "맴버가 답변했을 때")
                Divider().padding(.leading, 44)
                notifPermissionRow(icon: "hand.tap.fill", text: "재촉 알림을 받았을 때")
                Divider().padding(.leading, 44)
                notifPermissionRow(icon: "questionmark.circle.fill", text: "새 질문 알림")
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
                Text("방해 금지 시간 🌙")
                    .font(MongleFont.heading2())
                    .foregroundColor(MongleColor.textPrimary)
                Text("취침 시간에는 알림을 받지 않아요")
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
                    Text("오후 10:00 - 오전 8:00")
                        .font(MongleFont.body2Bold())
                        .foregroundColor(MongleColor.textPrimary)
                    Text("이 시간 동안은 알림이 전송되지 않아요")
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
