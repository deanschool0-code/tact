import Combine
import SwiftData
import SwiftUI

/// App-wide state: plan, free quota, paywall.
@MainActor
final class AppState: ObservableObject {
    @Published var quota: Quota?
    @Published var showPaywall = false
    let store = Store()
    private var storeObserver: AnyCancellable?

    var isPro: Bool { store.isPro || quota?.pro == true }

    init() {
        // Re-render views that read isPro when the Store changes.
        storeObserver = store.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        store.onEntitlement = { [weak self] jws in
            guard let q = try? await APIClient.shared.sendEntitlement(jws: jws) else { return }
            await MainActor.run { self?.quota = q }
        }
    }

    func start() async {
        await store.refresh(sendToServer: true)
        await refreshQuota()
        await store.loadProducts()
    }

    func refreshQuota() async {
        if let q = try? await APIClient.shared.quota() { quota = q }
    }

    /// Central error handling: limit errors open the paywall.
    func message(for error: Error) -> String {
        if let e = error as? APIError {
            if e.isLimit {
                quota?.remaining = 0
                showPaywall = true
                return "That's your \(Config.freeDaily) for today. Back tomorrow, or go unlimited."
            }
            return e.message
        }
        return error.localizedDescription
    }

    /// Saves to on-device history and to the keyboard's recent list.
    func remember(kind: ToolKind, title: String, outputs: [String], note: String = "", in context: ModelContext) {
        guard !outputs.isEmpty else { return }
        context.insert(Generation(kind: kind, title: title, outputs: outputs, note: note))
        try? context.save()
        if kind != .vibe && kind != .coach { SharedReplies.add(Array(outputs.prefix(4))) }
    }
}
