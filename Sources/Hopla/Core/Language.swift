import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, fr, en
    var id: String { rawValue }
}

/// Every user-facing string is written in both languages right where it is used: `tr("Bonjour", "Hello")`.
/// Adding a language means adding a parameter, which keeps translations next to the code that shows them.
func tr(_ fr: String, _ en: String) -> String {
    Settings.shared.resolvedLanguage == .en ? en : fr
}
