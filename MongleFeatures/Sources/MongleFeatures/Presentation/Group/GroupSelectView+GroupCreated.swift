import SwiftUI
import UIKit

// MARK: - Group Created Step

extension GroupSelectView {

  var inviteLink: String {
    "https://1cq1kfgvf1.execute-api.ap-northeast-2.amazonaws.com/invite/\(store.inviteCode)"
  }

  var shareText: String {
    L10n.tr("group_share_text", store.inviteCode, inviteLink)
  }

  var groupCreatedView: some View {
    VStack(alignment: .leading, spacing: MongleSpacing.lg) {
      // 프로세스 진행 UI
      HStack(spacing: MongleSpacing.xs) {
        Capsule()
          .fill(MongleColor.moodCalm)
          .frame(height: 4)
        Capsule()
          .fill(MongleColor.moodCalm)
          .frame(height: 4)
      }
      .padding(.bottom, MongleSpacing.sm)

      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text(L10n.tr("group_created_title"))
          .font(MongleFont.heading2())
          .foregroundColor(MongleColor.textPrimary)
        Text(L10n.tr("group_created_desc"))
          .font(MongleFont.body2())
          .foregroundColor(MongleColor.textSecondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // 초대코드 카드
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text(L10n.tr("group_invite_code"))
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.textSecondary)

        HStack {
          Text(store.inviteCode)
            .font(MongleFont.heading3())
            .foregroundColor(MongleColor.primary)

          Spacer()

          Button {
            UIPasteboard.general.string = store.inviteCode
            codeCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { codeCopied = false }
          } label: {
            Label(codeCopied ? L10n.tr("common_copied") : L10n.tr("common_copy"), systemImage: codeCopied ? "checkmark" : "doc.on.doc")
              .font(MongleFont.captionBold())
              .foregroundColor(codeCopied ? MongleColor.success : MongleColor.primary)
              .padding(.horizontal, MongleSpacing.sm)
              .padding(.vertical, MongleSpacing.xxs)
              .background(codeCopied ? MongleColor.success.opacity(0.12) : MongleColor.primaryLight)
              .clipShape(Capsule())
          }
          .animation(.easeInOut(duration: 0.2), value: codeCopied)
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.large).stroke(MongleColor.border, lineWidth: 1))
      }

      // 초대 링크
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text(L10n.tr("group_invite_link"))
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.textSecondary)

        HStack {
          Text(inviteLink)
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textPrimary)
            .lineLimit(1)
            .truncationMode(.middle)

          Spacer()

          Button {
            UIPasteboard.general.string = inviteLink
            linkCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { linkCopied = false }
          } label: {
            Label(linkCopied ? L10n.tr("common_copied") : L10n.tr("common_copy"), systemImage: linkCopied ? "checkmark" : "doc.on.doc")
              .font(MongleFont.captionBold())
              .foregroundColor(linkCopied ? MongleColor.success : MongleColor.primary)
              .padding(.horizontal, MongleSpacing.sm)
              .padding(.vertical, MongleSpacing.xxs)
              .background(linkCopied ? MongleColor.success.opacity(0.12) : MongleColor.primaryLight)
              .clipShape(Capsule())
          }
          .animation(.easeInOut(duration: 0.2), value: linkCopied)
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.large).stroke(MongleColor.border, lineWidth: 1))
      }
    }
  }
}
