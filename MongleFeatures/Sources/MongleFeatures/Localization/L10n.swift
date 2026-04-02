import Foundation

/// Localization helper for MongleFeatures module.
///
/// Usage:
/// - `L10n.tr("login_title")` for simple keys
/// - `L10n.tr("error_server", 500)` for format strings with arguments
public enum L10n {
    public static func tr(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }

    public static func tr(_ key: String, _ args: CVarArg...) -> String {
        String(format: NSLocalizedString(key, bundle: .module, comment: ""), arguments: args)
    }
}
