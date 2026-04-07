//
//  MongleTextField.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import SwiftUI

struct MongleTextField: View {
    let title: String?
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var errorMessage: String? = nil
    var keyboardType: UIKeyboardType = .default
    var leadingIcon: String? = nil
    var helperText: String? = nil

    @State private var isSecureTextVisible = false
    @FocusState private var isFocused: Bool

    init(
        title: String? = nil,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        errorMessage: String? = nil,
        keyboardType: UIKeyboardType = .default,
        leadingIcon: String? = nil,
        helperText: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.errorMessage = errorMessage
        self.keyboardType = keyboardType
        self.leadingIcon = leadingIcon
        self.helperText = helperText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            // Title
            if let title = title {
                Text(title)
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textSecondary)
            }

            // Input Field
            HStack(spacing: MongleSpacing.sm) {
                // Leading Icon
                if let leadingIcon = leadingIcon {
                    Image(systemName: leadingIcon)
                        .font(.system(size: 18))
                        .foregroundColor(isFocused ? MongleColor.primary : MongleColor.textHint)
                }

                // Text Input
                if isSecure && !isSecureTextVisible {
                    SecureField(placeholder, text: $text)
                        .foregroundColor(MongleColor.textPrimary)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundColor(MongleColor.textPrimary)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                }

                // Trailing Icons
                if isSecure {
                    Button {
                        isSecureTextVisible.toggle()
                    } label: {
                        Image(systemName: isSecureTextVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16))
                            .foregroundColor(MongleColor.textHint)
                    }
                }

                // Clear Button
                if !text.isEmpty && !isSecure {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(MongleColor.textHint)
                    }
                }
            }
            .font(MongleFont.body1())
            .padding(.horizontal, MongleSpacing.md)
            .frame(height: 52)
            .background(fieldBackgroundColor)
            .cornerRadius(MongleRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.medium)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)

            // Helper or Error Text
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                HStack(spacing: MongleSpacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(MongleFont.caption())
                }
                .foregroundColor(MongleColor.error)
            } else if let helperText = helperText {
                Text(helperText)
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textHint)
            }
        }
    }

    private var fieldBackgroundColor: Color {
        isFocused ? MongleColor.background : MongleColor.surface
    }

    private var borderColor: Color {
        if let errorMessage, !errorMessage.isEmpty {
            return MongleColor.error
        }
        return isFocused ? MongleColor.primary : MongleColor.border
    }
}

// MARK: - Text Area (여러 줄 입력)
struct MongleTextArea: View {
    let title: String?
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 120
    var errorMessage: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            if let title = title {
                Text(title)
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textSecondary)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(MongleFont.body1())
                        .foregroundColor(MongleColor.textHint)
                        .padding(.horizontal, MongleSpacing.md)
                        .padding(.vertical, MongleSpacing.md)
                }

                TextEditor(text: $text)
                    .font(MongleFont.body1())
                    .foregroundColor(MongleColor.textPrimary)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, MongleSpacing.sm)
                    .padding(.vertical, MongleSpacing.sm)
            }
            .frame(minHeight: minHeight)
            .background(isFocused ? MongleColor.background : MongleColor.surface)
            .cornerRadius(MongleRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.medium)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
            )

            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                HStack(spacing: MongleSpacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(MongleFont.caption())
                }
                .foregroundColor(MongleColor.error)
            }
        }
    }

    private var borderColor: Color {
        if let errorMessage, !errorMessage.isEmpty {
            return MongleColor.error
        }
        return isFocused ? MongleColor.primary : MongleColor.border
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            Text("기본 텍스트 필드")
                .font(MongleFont.heading3())

            MongleTextField(
                title: "이메일",
                placeholder: "example@email.com",
                text: .constant(""),
                keyboardType: .emailAddress,
                leadingIcon: "envelope"
            )

            MongleTextField(
                title: "비밀번호",
                placeholder: "최소 6자 이상",
                text: .constant(""),
                isSecure: true,
                leadingIcon: "lock"
            )

            MongleTextField(
                title: "닉네임",
                placeholder: "닉네임을 입력해주세요",
                text: .constant("홍길동"),
                helperText: "2-10자 이내로 입력해주세요"
            )

            MongleTextField(
                title: "비밀번호",
                placeholder: "최소 6자 이상",
                text: .constant("abc"),
                isSecure: true,
                errorMessage: "비밀번호가 너무 짧습니다"
            )

            Text("타이틀 없는 필드")
                .font(MongleFont.heading3())

            MongleTextField(
                placeholder: "검색어를 입력하세요",
                text: .constant(""),
                leadingIcon: "magnifyingglass"
            )

            Text("텍스트 영역")
                .font(MongleFont.heading3())

            MongleTextArea(
                title: "답변",
                placeholder: "답변을 입력해주세요...",
                text: .constant("")
            )
        }
        .padding()
    }
    .background(MongleColor.surface)
}
