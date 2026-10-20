import Foundation
import Security

/// Random install ID kept in the Keychain. It is not tied to any personal info.
enum DeviceID {
    private static let account = "tact.device-id"

    static let value: String = {
        if let existing = read() { return existing }
        let id = UUID().uuidString
        save(id)
        return id
    }()

    private static func read() -> String? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrAccount as String: account,
                                kSecReturnData as String: true,
                                kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func save(_ id: String) {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrAccount as String: account,
                                kSecValueData as String: Data(id.utf8),
                                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock]
        SecItemAdd(q as CFDictionary, nil)
    }
}

struct APIError: LocalizedError, Equatable {
    var status: Int
    var code: String
    var message: String
    var errorDescription: String? { message }

    var isLimit: Bool { code == "limit_reached" }
    static let offline = APIError(status: 0, code: "offline", message: "Can't reach Tact right now. Check your connection.")
}

struct GenerateRequest: Encodable {
    struct Line: Encodable { let from: String; let text: String }
    var kind: ToolKind
    var transcript: [Line] = []
    var text: String = ""
    var tone: String = ""
    var goal: String = ""
    var style: String = Pref.styleValue
    var extra: String = ""
    var tweak: String = ""
    var base: String = ""
    var voice: [String] = Pref.voice

    init(kind: ToolKind, lines: [ChatLine] = [], text: String = "", tone: Tone? = nil, goal: Goal? = nil,
         extra: String = "", tweak: TweakKind? = nil, base: String = "") {
        self.kind = kind
        self.transcript = lines.map { Line(from: $0.from.rawValue, text: $0.text) }
        self.text = text
        self.tone = tone?.rawValue ?? ""
        self.goal = goal?.rawValue ?? ""
        self.extra = extra
        self.tweak = tweak?.rawValue ?? ""
        self.base = base
    }
}

private struct Envelope<T: Decodable>: Decodable {
    let result: T
    let quota: Quota
}

private struct CoachEnvelope: Decodable {
    let reply: String
    let quota: Quota
}

private struct EntitlementEnvelope: Decodable {
    let pro: Bool
    let quota: Quota
}

private struct ErrorBody: Decodable {
    let error: String
    let message: String
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 60
        c.waitsForConnectivity = false
        return URLSession(configuration: c)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    var baseURL: URL {
        let stored = UserDefaults.standard.string(forKey: Pref.serverURL) ?? ""
        let raw = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: raw.isEmpty ? Config.defaultServerURL : raw) ?? URL(string: Config.defaultServerURL)!
    }

    func generate<T: Decodable>(_ body: GenerateRequest, as: T.Type) async throws -> (T, Quota) {
        let env: Envelope<T> = try await send("POST", "/v1/generate", body: body)
        return (env.result, env.quota)
    }

    func coach(_ turns: [CoachTurn], context: [ChatLine]?) async throws -> (String, Quota) {
        struct Body: Encodable {
            struct M: Encodable { let role: String; let text: String }
            struct L: Encodable { let from: String; let text: String }
            let messages: [M]
            let context: [L]?
        }
        let body = Body(messages: turns.map { .init(role: $0.role, text: $0.text) },
                        context: context?.map { .init(from: $0.from.rawValue, text: $0.text) })
        let env: CoachEnvelope = try await send("POST", "/v1/coach", body: body)
        return (env.reply, env.quota)
    }

    func quota() async throws -> Quota {
        try await send("GET", "/v1/quota", body: Optional<String>.none)
    }

    @discardableResult
    func sendEntitlement(jws: String) async throws -> Quota {
        struct Body: Encodable { let jws: String }
        let env: EntitlementEnvelope = try await send("POST", "/v1/entitlement", body: Body(jws: jws))
        return env.quota
    }

    func deleteServerData() async throws {
        struct Out: Decodable { let deleted: Int }
        let _: Out = try await send("POST", "/v1/data/delete", body: Optional<String>.none)
    }

    func health() async -> Bool {
        var req = URLRequest(url: baseURL.appending(path: "/health"))
        req.timeoutInterval = 8
        guard let (_, resp) = try? await session.data(for: req) else { return false }
        return (resp as? HTTPURLResponse)?.statusCode == 200
    }

    private func send<B: Encodable, T: Decodable>(_ method: String, _ path: String, body: B?) async throws -> T {
        var req = URLRequest(url: baseURL.appending(path: path))
        req.httpMethod = method
        req.setValue(DeviceID.value, forHTTPHeaderField: "X-Device-ID")
        if !Config.clientToken.isEmpty { req.setValue(Config.clientToken, forHTTPHeaderField: "X-Client-Token") }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(body)
        }
        let result: (Data, URLResponse)
        do {
            result = try await session.data(for: req)
        } catch {
            throw APIError.offline
        }
        let (data, resp) = result
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            if let e = try? decoder.decode(ErrorBody.self, from: data) {
                throw APIError(status: status, code: e.error, message: e.message)
            }
            throw APIError(status: status, code: "http_\(status)", message: "That didn't land. Try again?")
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError(status: status, code: "decode", message: "Got a weird answer back. Try again?")
        }
    }
}
