import Foundation
import StoreKit

/// StoreKit 2 subscriptions. Apple handles billing; cancelling is one tap in Manage Subscription.
@MainActor
final class Store: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro = false
    @Published private(set) var loadError: String?
    @Published var purchasing = false

    /// Called with a fresh signed transaction so the server can verify Pro.
    var onEntitlement: ((String) async -> Void)?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
    }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Config.productIDs)
            products = loaded.sorted { $0.price < $1.price }
            loadError = loaded.isEmpty ? "Plans aren't available yet." : nil
        } catch {
            loadError = "Couldn't load plans. Check your connection."
        }
    }

    /// Returns true when the purchase went through.
    func purchase(_ product: Product) async throws -> Bool {
        purchasing = true
        defer { purchasing = false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            await handle(verification)
            return isPro
        case .pending, .userCancelled:
            return false
        @unknown default:
            return false
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh(sendToServer: true)
    }

    func refresh(sendToServer: Bool = false) async {
        var pro = false
        var latest: String?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result,
                  Config.productIDs.contains(t.productID),
                  t.revocationDate == nil else { continue }
            pro = true
            latest = result.jwsRepresentation
        }
        isPro = pro
        if sendToServer, let latest { await onEntitlement?(latest) }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
        await refresh()
        if transaction.revocationDate == nil { await onEntitlement?(result.jwsRepresentation) }
    }

    func label(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else { return product.displayName }
        switch period.unit {
        case .year: return "Yearly"
        case .month: return "Monthly"
        case .week: return "Weekly"
        default: return product.displayName
        }
    }

    func perMonth(_ product: Product) -> String? {
        guard product.subscription?.subscriptionPeriod.unit == .year else { return nil }
        let monthly = product.price / 12
        return monthly.formatted(product.priceFormatStyle) + "/mo"
    }
}
