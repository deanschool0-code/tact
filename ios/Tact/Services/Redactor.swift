import Foundation

/// Strips phone numbers, emails, links and street addresses on the device before anything is sent.
enum Redactor {
    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue
        | NSTextCheckingResult.CheckingType.link.rawValue
        | NSTextCheckingResult.CheckingType.address.rawValue)
    private static let email = try? NSRegularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: .caseInsensitive)
    private static let handle = try? NSRegularExpression(pattern: "(?<![\\w@])@[A-Za-z0-9._]{3,30}")

    static func redact(_ text: String) -> String {
        var out = text
        if let email {
            out = email.stringByReplacingMatches(in: out, range: NSRange(out.startIndex..., in: out), withTemplate: "[email]")
        }
        if let detector {
            let matches = detector.matches(in: out, range: NSRange(out.startIndex..., in: out))
            for m in matches.reversed() {
                guard let r = Range(m.range, in: out) else { continue }
                let label: String
                switch m.resultType {
                case .phoneNumber: label = "[number]"
                case .address: label = "[address]"
                default: label = "[link]"
                }
                out.replaceSubrange(r, with: label)
            }
        }
        if let handle {
            out = handle.stringByReplacingMatches(in: out, range: NSRange(out.startIndex..., in: out), withTemplate: "[handle]")
        }
        return out
    }

    static func redact(_ lines: [ChatLine]) -> [ChatLine] {
        lines.map { ChatLine(id: $0.id, from: $0.from, text: redact($0.text)) }
    }
}
