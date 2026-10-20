import Foundation

/// Recent replies shared between the app and the keyboard through the App Group.
enum SharedReplies {
    static let groupID = "group.com.deancarson.tact"
    private static let key = "recentReplies"
    private static let limit = 15

    private static var defaults: UserDefaults { UserDefaults(suiteName: groupID) ?? .standard }

    static func load() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    static func add(_ replies: [String]) {
        var current = load()
        for r in replies.reversed() where !r.isEmpty {
            current.removeAll { $0 == r }
            current.insert(r, at: 0)
        }
        defaults.set(Array(current.prefix(limit)), forKey: key)
    }

    static func clear() {
        defaults.removeObject(forKey: key)
    }
}
