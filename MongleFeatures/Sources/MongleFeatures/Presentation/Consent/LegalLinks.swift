//
//  LegalLinks.swift
//  MongleFeatures
//
//  약관/개인정보 처리방침 노션 링크.
//  한국어(ko) / 영어(en) / 일본어(ja) 별 개별 페이지가 Notion 에 정리되어 있으며,
//  기기 `Locale` 에 따라 자동 선택된다. 지원하지 않는 언어는 영어로 폴백.
//

import Foundation

public enum LegalLinks {

    // MARK: - Terms of Service

    private static let termsKO = URL(string: "https://bedecked-latency-99c.notion.site/terms-ko-33c4d36af6f68054a527c510d4f98b7f")!
    private static let termsEN = URL(string: "https://bedecked-latency-99c.notion.site/terms-en-33c4d36af6f6807eae71c6f530a4457d")!
    private static let termsJA = URL(string: "https://bedecked-latency-99c.notion.site/terms-ja-33c4d36af6f680478c85e99a04fa629c")!

    // MARK: - Privacy Policy

    private static let privacyKO = URL(string: "https://bedecked-latency-99c.notion.site/privacy-policy-ko-33c4d36af6f680ffb927c10bc5d7bd1b")!
    private static let privacyEN = URL(string: "https://bedecked-latency-99c.notion.site/privacy-policy-en-33c4d36af6f680c1a224efb392dc488e")!
    private static let privacyJA = URL(string: "https://bedecked-latency-99c.notion.site/privacy-policy-ja-33c4d36af6f680e89cfbec8fb659d491")!

    // MARK: - Public accessors (locale-aware)

    /// 현재 기기 언어에 맞는 서비스 이용약관 URL.
    public static var termsURL: URL {
        switch currentLegalLang() {
        case .ko: return termsKO
        case .ja: return termsJA
        case .en: return termsEN
        }
    }

    /// 현재 기기 언어에 맞는 개인정보 처리방침 URL.
    public static var privacyURL: URL {
        switch currentLegalLang() {
        case .ko: return privacyKO
        case .ja: return privacyJA
        case .en: return privacyEN
        }
    }

    // MARK: - Private

    private enum LegalLang { case ko, en, ja }

    private static func currentLegalLang() -> LegalLang {
        let code: String?
        if #available(iOS 16, *) {
            code = Locale.current.language.languageCode?.identifier
        } else {
            code = Locale.current.languageCode
        }
        switch code?.lowercased() {
        case "ko": return .ko
        case "ja": return .ja
        default:   return .en
        }
    }
}
