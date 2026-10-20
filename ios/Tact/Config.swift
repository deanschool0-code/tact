import Foundation

enum Config {
    /// Where the Tact server runs. The iOS Simulator can reach your Mac at localhost.
    /// On a real iPhone, change it in Settings → Developer (e.g. your Cloudflare Tunnel https URL).
    static let defaultServerURL = "http://localhost:5580"

    /// Optional shared header value; must match CLIENT_TOKEN in server/.env. A speed bump, not security.
    static let clientToken = ""

    static let freeDaily = 3
    static let appGroup = "group.com.deancarson.tact"
    static let productIDs = ["tact.pro.monthly", "tact.pro.yearly"]
    static let privacyURL = URL(string: "https://example.com/tact/privacy")!  // TODO: your page
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}

/// Keys for @AppStorage, in one place.
enum Pref {
    static let onboarded = "onboarded"
    static let ageConfirmed = "ageConfirmed"
    static let style = "style"
    static let defaultTone = "defaultTone"
    static let voiceSamples = "voiceSamples"   // newline-separated
    static let redact = "redact"
    static let serverURL = "serverURL"

    static var voice: [String] {
        (UserDefaults.standard.string(forKey: voiceSamples) ?? "")
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    static var styleValue: String { UserDefaults.standard.string(forKey: style) ?? "" }
}
