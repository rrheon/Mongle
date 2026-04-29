//
//  ApsEnvironmentDetector.swift
//  MongleFeatures
//

import Foundation

enum ApsEnvironmentDetector {

    /// provisioning profile 의 aps-environment entitlement 으로 환경을 판단.
    ///
    /// - 시뮬레이터: embedded.mobileprovision 이 존재하지 않으나 토큰은 항상 sandbox
    ///   로 발급되므로 무조건 "sandbox" 반환.
    /// - 실기기 (Development profile): aps-environment = "development" → "sandbox"
    /// - 실기기 (Distribution profile, TestFlight/App Store): aps-environment =
    ///   "production" → "production"
    /// - 정상 경로 실패 시 fallback 은 "production" — App Store 빌드(정식 배포)에
    ///   embedded.mobileprovision 이 stripped 되는 케이스 보호.
    static func current() -> String {
        #if targetEnvironment(simulator)
        return "sandbox"
        #else
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
        #endif
    }
}
