//
//  ConsentView.swift
//  MongleFeatures
//
//  약관 동의 화면. 회원가입 직후 또는 약관 개정 시 노출.
//

import SwiftUI
import SafariServices
import ComposableArchitecture

struct ConsentView: View {
    @Bindable var store: StoreOf<ConsentFeature>
    @State private var safariURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            // 상단 바 (뒤로가기)
            HStack {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MongleColor.textPrimary)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
            .padding(.horizontal, MongleSpacing.sm)
            .padding(.top, MongleSpacing.xs)

            // 헤더
            VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                Text(L10n.tr("consent_title"))
                    .font(MongleFont.heading1())
                    .foregroundStyle(MongleColor.textPrimary)

                Text(L10n.tr("consent_subtitle"))
                    .font(MongleFont.body2())
                    .foregroundStyle(MongleColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MongleSpacing.xl)
            .padding(.top, MongleSpacing.sm)
            .padding(.bottom, MongleSpacing.lg)

            // 동의 항목 리스트
            VStack(spacing: 0) {
                allAgreeRow

                Divider()
                    .padding(.vertical, MongleSpacing.sm)
                    .padding(.horizontal, MongleSpacing.md)

                consentRow(
                    title: L10n.tr("consent_age"),
                    isOn: store.ageAgreed,
                    onTap: { store.send(.toggleAge) },
                    onLink: nil
                )

                consentRow(
                    title: L10n.tr("consent_terms"),
                    isOn: store.termsAgreed,
                    onTap: { store.send(.toggleTerms) },
                    onLink: { safariURL = LegalLinks.termsURL }
                )

                consentRow(
                    title: L10n.tr("consent_privacy"),
                    isOn: store.privacyAgreed,
                    onTap: { store.send(.togglePrivacy) },
                    onLink: { safariURL = LegalLinks.privacyURL }
                )
            }
            .padding(.vertical, MongleSpacing.md)
            .background(MongleColor.cardBackgroundSolid)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            .padding(.horizontal, MongleSpacing.xl)

            Spacer()

            // 제출 버튼
            Button {
                store.send(.submitTapped)
            } label: {
                HStack {
                    if store.isSubmitting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text(L10n.tr("consent_submit"))
                            .font(MongleFont.body1Bold())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MongleSpacing.md)
                .foregroundStyle(.white)
                .background(store.canSubmit ? MongleColor.primary : MongleColor.border)
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            }
            .disabled(!store.canSubmit)
            .padding(.horizontal, MongleSpacing.xl)
            .padding(.bottom, MongleSpacing.xl)
        }
        .background(MongleColor.background)
        .alert(
            "",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.send(.dismissError) } }
            ),
            actions: {
                Button(L10n.tr("common_confirm")) { store.send(.dismissError) }
            },
            message: { Text(store.errorMessage ?? "") }
        )
        .sheet(item: $safariURL) { url in
            SafariSheet(url: url)
                .ignoresSafeArea()
        }
    }

    // MARK: 전체 동의

    private var allAgreeRow: some View {
        Button {
            store.send(.toggleAll(!store.allAgreed))
        } label: {
            HStack(spacing: MongleSpacing.sm) {
                checkboxIcon(checked: store.allAgreed)
                Text(L10n.tr("consent_all"))
                    .font(MongleFont.body1Bold())
                    .foregroundStyle(MongleColor.textPrimary)
                Spacer()
            }
            .padding(.horizontal, MongleSpacing.md)
            .padding(.vertical, MongleSpacing.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: 개별 항목

    private func consentRow(
        title: String,
        isOn: Bool,
        onTap: @escaping () -> Void,
        onLink: (() -> Void)?
    ) -> some View {
        HStack(spacing: MongleSpacing.sm) {
            Button(action: onTap) {
                HStack(spacing: MongleSpacing.sm) {
                    checkboxIcon(checked: isOn)
                    Text(title)
                        .font(MongleFont.body2())
                        .foregroundStyle(MongleColor.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if let onLink {
                Button(action: onLink) {
                    Text(L10n.tr("consent_view"))
                        .font(MongleFont.caption())
                        .foregroundStyle(MongleColor.textHint)
                        .underline()
                }
            }
        }
        .padding(.horizontal, MongleSpacing.md)
        .padding(.vertical, MongleSpacing.xs)
    }

    private func checkboxIcon(checked: Bool) -> some View {
        Image(systemName: checked ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 24, weight: .regular))
            .foregroundStyle(checked ? MongleColor.primary : MongleColor.border)
    }
}

// MARK: - Safari Sheet

private struct SafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
