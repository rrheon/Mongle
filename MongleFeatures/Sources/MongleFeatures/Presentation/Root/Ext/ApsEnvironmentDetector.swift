//
//  ApsEnvironmentDetector.swift
//  MongleFeatures
//

import Foundation

enum ApsEnvironmentDetector {

    /// embedded.mobileprovision 의 Entitlements.aps-environment 를 읽어
    /// "sandbox" 또는 "production" 을 반환한다. provisioning profile 이 없는
    /// (App Store 정식 배포) 경우 production 으로 간주.
    static func current() -> String {
        guard
            let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
            let data = try? Data(contentsOf: url),
            let raw = String(data: data, encoding: .ascii)
        else {
            return "production"
        }

        guard
            let plistStart = raw.range(of: "<?xml"),
            let plistEnd = raw.range(of: "</plist>")
        else {
            return "production"
        }

        let plistString = String(raw[plistStart.lowerBound..<plistEnd.upperBound])
        guard
            let plistData = plistString.data(using: .utf8),
            let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
            let entitlements = plist["Entitlements"] as? [String: Any],
            let apsEnv = entitlements["aps-environment"] as? String
        else {
            return "production"
        }

        return apsEnv == "development" ? "sandbox" : "production"
    }
}
