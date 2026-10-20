import Foundation
import SwiftData

enum Side: String, Codable, Hashable {
    case me, them
    var flipped: Side { self == .me ? .them : .me }
}

struct ChatLine: Identifiable, Hashable, Codable {
    var id = UUID()
    var from: Side
    var text: String
}

enum ToolKind: String, Codable, CaseIterable {
    case reply, opener, lines, vibe, bio, tweak, coach

    var title: String {
        switch self {
        case .reply: return "Reply"
        case .opener: return "Opener"
        case .lines: return "Pickup lines"
        case .vibe: return "Vibe check"
        case .bio: return "Bio review"
        case .tweak: return "Tweak"
        case .coach: return "Coach"
        }
    }

    var systemImage: String {
        switch self {
        case .reply: return "bubble.left.and.text.bubble.right.fill"
        case .opener: return "hand.wave.fill"
        case .lines: return "sparkles"
        case .vibe: return "waveform.path.ecg"
        case .bio: return "person.text.rectangle.fill"
        case .tweak: return "slider.horizontal.3"
        case .coach: return "graduationcap.fill"
        }
    }
}

enum Tone: String, CaseIterable, Identifiable, Codable {
    case chill, funny, flirty, bold, sweet, witty
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var systemImage: String {
        switch self {
        case .chill: return "leaf.fill"
        case .funny: return "face.smiling.inverse"
        case .flirty: return "heart.fill"
        case .bold: return "bolt.fill"
        case .sweet: return "sun.max.fill"
        case .witty: return "lightbulb.fill"
        }
    }
}

enum Goal: String, CaseIterable, Identifiable, Codable {
    case keepGoing = "keep_going"
    case askOut = "ask_out"
    case recover
    case changeTopic = "change_topic"
    case getNumber = "get_number"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .keepGoing: return "Keep it going"
        case .askOut: return "Ask them out"
        case .recover: return "Save an awkward moment"
        case .changeTopic: return "New topic"
        case .getNumber: return "Move off the app"
        }
    }
}

enum Style: String, CaseIterable, Identifiable, Codable {
    case funny, chill, bold, sweet
    var id: String { rawValue }
    var label: String {
        switch self {
        case .funny: return "The funny one"
        case .chill: return "Laid-back"
        case .bold: return "Confident"
        case .sweet: return "Warm"
        }
    }
}

enum TweakKind: String, CaseIterable, Identifiable {
    case shorter, funnier, bolder, softer
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var systemImage: String {
        switch self {
        case .shorter: return "arrow.down.right.and.arrow.up.left"
        case .funnier: return "face.smiling"
        case .bolder: return "bolt"
        case .softer: return "cloud"
        }
    }
}

// MARK: - API results

struct ReplyOption: Codable, Hashable, Identifiable {
    var text: String
    var why: String = ""
    var id: String { text }
}

struct ReplyResult: Codable {
    var read: String? = nil
    var boundary: Bool? = nil
    var replies: [ReplyOption]
}

struct VibeResult: Codable {
    var interest: Int
    var summary: String
    var greenFlags: [String]
    var redFlags: [String]
    var nextMove: String
    var boundary: Bool?
}

struct BioResult: Codable {
    var score: Int
    var summary: String
    var strengths: [String]
    var fixes: [String]
    var rewrites: [ReplyOption]
}

struct Quota: Codable, Equatable {
    var pro: Bool
    var used: Int
    var limit: Int
    var remaining: Int?
}

struct CoachTurn: Identifiable, Hashable, Codable {
    var id = UUID()
    var role: String  // "user" | "assistant"
    var text: String
}

// MARK: - Local history (SwiftData, stays on the phone)

@Model
final class Generation {
    var id: UUID
    var kindRaw: String
    var title: String
    var outputs: [String]
    var note: String
    var favourite: Bool
    var createdAt: Date

    init(kind: ToolKind, title: String, outputs: [String], note: String = "", favourite: Bool = false) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.title = title
        self.outputs = outputs
        self.note = note
        self.favourite = favourite
        self.createdAt = .now
    }

    var kind: ToolKind { ToolKind(rawValue: kindRaw) ?? .reply }
}
