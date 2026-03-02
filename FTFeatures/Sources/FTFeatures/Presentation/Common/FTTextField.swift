//
//  FTTextField.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import SwiftUI

struct FTTextField: View {
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
        VStack(alignment: .leading, spacing: FTSpacing.xs) {
            // Title
            if let title = title {
                Text(title)
                    .font(FTFont.body2())
                    .foregroundColor(FTColor.textSecondary)
            }

            // Input Field
            HStack(spacing: FTSpacing.sm) {
                // Leading Icon
                if let leadingIcon = leadingIcon {
                    Image(systemName: leadingIcon)
                        .font(.system(size: 18))
                        .foregroundColor(isFocused ? FTColor.primary : FTColor.textHint)
                }

                // Text Input
                if isSecure && !isSecureTextVisible {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
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
                            .foregroundColor(FTColor.textHint)
                    }
                }

                // Clear Button
                if !text.isEmpty && !isSecure {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(FTColor.textHint)
                    }
                }
            }
            .font(FTFont.body1())
            .padding(.horizontal, FTSpacing.md)
            .frame(height: 52)
            .background(fieldBackgroundColor)
            .cornerRadius(FTRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: FTRadius.medium)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)

            // Helper or Error Text
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                HStack(spacing: FTSpacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(FTFont.caption())
                }
                .foregroundColor(FTColor.error)
            } else if let helperText = helperText {
                Text(helperText)
                    .font(FTFont.caption())
                    .foregroundColor(FTColor.textHint)
            }
        }
    }

    private var fieldBackgroundColor: Color {
        isFocused ? FTColor.background : FTColor.surface
    }

    private var borderColor: Color {
        if errorMessage != nil && !errorMessage!.isEmpty {
            return FTColor.error
        }
        return isFocused ? FTColor.primary : FTColor.border
    }
}

// MARK: - Text Area (여러 줄 입력)
struct FTTextArea: View {
    let title: String?
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 120
    var errorMessage: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FTSpacing.xs) {
            if let title = title {
                Text(title)
                    .font(FTFont.body2())
                    .foregroundColor(FTColor.textSecondary)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(FTFont.body1())
                        .foregroundColor(FTColor.textHint)
                        .padding(.horizontal, FTSpacing.md)
                        .padding(.vertical, FTSpacing.md)
                }

                TextEditor(text: $text)
                    .font(FTFont.body1())
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, FTSpacing.sm)
                    .padding(.vertical, FTSpacing.sm)
            }
            .frame(minHeight: minHeight)
            .background(isFocused ? FTColor.background : FTColor.surface)
            .cornerRadius(FTRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: FTRadius.medium)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
            )

            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                HStack(spacing: FTSpacing.xxs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(FTFont.caption())
                }
                .foregroundColor(FTColor.error)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil && !errorMessage!.isEmpty {
            return FTColor.error
        }
        return isFocused ? FTColor.primary : FTColor.border
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            Text("기본 텍스트 필드")
                .font(FTFont.heading3())

            FTTextField(
                title: "이메일",
                placeholder: "example@email.com",
                text: .constant(""),
                keyboardType: .emailAddress,
                leadingIcon: "envelope"
            )

            FTTextField(
                title: "비밀번호",
                placeholder: "최소 6자 이상",
                text: .constant(""),
                isSecure: true,
                leadingIcon: "lock"
            )

            FTTextField(
                title: "닉네임",
                placeholder: "닉네임을 입력해주세요",
                text: .constant("홍길동"),
                helperText: "2-10자 이내로 입력해주세요"
            )

            FTTextField(
                title: "비밀번호",
                placeholder: "최소 6자 이상",
                text: .constant("abc"),
                isSecure: true,
                errorMessage: "비밀번호가 너무 짧습니다"
            )

            Text("타이틀 없는 필드")
                .font(FTFont.heading3())

            FTTextField(
                placeholder: "검색어를 입력하세요",
                text: .constant(""),
                leadingIcon: "magnifyingglass"
            )

            Text("텍스트 영역")
                .font(FTFont.heading3())

            FTTextArea(
                title: "답변",
                placeholder: "답변을 입력해주세요...",
                text: .constant("")
            )
        }
        .padding()
    }
    .background(FTColor.surface)
}
