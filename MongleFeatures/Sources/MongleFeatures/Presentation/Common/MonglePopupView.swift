import SwiftUI

// MARK: - Reusable Popup View

struct MonglePopupView<ExtraContent: View>: View {
    struct Icon {
        let systemName: String
        let foregroundColor: Color
        let backgroundColor: Color
    }

    let icon: Icon
    let title: String
    let description: String
    let note: String?
    let primaryLabel: String
    let secondaryLabel: String
    let isPrimaryEnabled: Bool
    let onPrimary: () -> Void
    let onSecondary: () -> Void
    let extraContent: () -> ExtraContent

    init(
        icon: Icon,
        title: String,
        description: String,
        note: String? = nil,
        primaryLabel: String,
        secondaryLabel: String,
        isPrimaryEnabled: Bool = true,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void,
        @ViewBuilder extraContent: @escaping () -> ExtraContent
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.note = note
        self.primaryLabel = primaryLabel
        self.secondaryLabel = secondaryLabel
        self.isPrimaryEnabled = isPrimaryEnabled
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
        self.extraContent = extraContent
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onSecondary() }

            VStack(spacing: MongleSpacing.lg) {
                iconCircle
                textSection
                extraContent()
                buttonSection
            }
            .padding(MongleSpacing.lg)
            .frame(maxWidth: 344)
            .monglePanel(background: .white, cornerRadius: MongleRadius.xl, shadowOpacity: 0.08)
            .padding(.horizontal, MongleSpacing.lg)
        }
    }

    private var iconCircle: some View {
        Circle()
            .fill(icon.backgroundColor)
            .frame(width: 92, height: 92)
            .overlay(
                Image(systemName: icon.systemName)
                    .font(.system(size: 36))
                    .foregroundColor(icon.foregroundColor)
            )
    }

    private var textSection: some View {
        VStack(spacing: MongleSpacing.sm) {
            Text(title)
                .font(MongleFont.heading3())
                .foregroundColor(MongleColor.textPrimary)

            Text(description)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            if let note {
                Text(note)
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textHint)
            }
        }
    }

    private var buttonSection: some View {
        VStack(spacing: MongleSpacing.sm) {
            MongleButtonPrimary(primaryLabel) {
                onPrimary()
            }
            .opacity(isPrimaryEnabled ? 1 : 0.5)
            .disabled(!isPrimaryEnabled)

            Button(secondaryLabel) {
                onSecondary()
            }
            .font(MongleFont.body2())
            .foregroundColor(MongleColor.textHint)
        }
    }
}

// MARK: - EmptyView convenience init

extension MonglePopupView where ExtraContent == EmptyView {
    init(
        icon: Icon,
        title: String,
        description: String,
        note: String? = nil,
        primaryLabel: String,
        secondaryLabel: String,
        isPrimaryEnabled: Bool = true,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void
    ) {
        self.init(
            icon: icon,
            title: title,
            description: description,
            note: note,
            primaryLabel: primaryLabel,
            secondaryLabel: secondaryLabel,
            isPrimaryEnabled: isPrimaryEnabled,
            onPrimary: onPrimary,
            onSecondary: onSecondary,
            extraContent: { EmptyView() }
        )
    }
}
