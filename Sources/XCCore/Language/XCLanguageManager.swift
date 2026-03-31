import Foundation

public enum LanguageManager {
    private static let key = "xctoolkit.language.identifier"

    public static var currentLanguageIdentifier: String {
        get { UserDefaults.standard.string(forKey: key) ?? Locale.preferredLanguages.first ?? "en" }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    public static func localized(
        _ key: String,
        table: String? = nil,
        bundle: Bundle = .main
    ) -> String {
        let identifier = currentLanguageIdentifier
        guard
            let path = bundle.path(forResource: identifier, ofType: "lproj"),
            let languageBundle = Bundle(path: path)
        else {
            return NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
        }

        return NSLocalizedString(key, tableName: table, bundle: languageBundle, value: key, comment: "")
    }
}
