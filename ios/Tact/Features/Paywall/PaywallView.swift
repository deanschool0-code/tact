import StoreKit
import SwiftUI

/// S03 — an honest paywall: the close button is always there, free use stays, no weekly plan.
struct PaywallView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var selected: String?
    @State private var error: String?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.l) {
                    Image(systemName: "infinity.circle.fill").font(.system(size: 52)).foregroundStyle(Theme.accent)
                        .padding(.top, Theme.Space.xxl)
                        .accessibilityHidden(true)
                    Text("Tact Pro").font(Theme.Font.display).foregroundStyle(Theme.text)
                    Text("Unlimited replies, openers, vibe checks and coaching.")
                        .font(Theme.Font.body).foregroundStyle(Theme.textMuted)

                    VStack(alignment: .leading, spacing: Theme.Space.m) {
                        InfoLine(systemImage: "infinity", text: "No daily limit on any tool", color: Theme.accent)
                        InfoLine(systemImage: "slider.horizontal.3", text: "Unlimited tweaks: shorter, funnier, bolder, softer", color: Theme.accent)
                        InfoLine(systemImage: "keyboard", text: "Every reply ready in the Tact keyboard", color: Theme.accent)
                        InfoLine(systemImage: "gift", text: "Not ready? You still get \(Config.freeDaily) free every day.", color: Theme.accent)
                    }
                    .card()

                    if store.products.isEmpty {
                        if let err = store.loadError {
                            ErrorBanner(message: err) { Task { await store.loadProducts() } }
                        } else {
                            HStack { Spacer(); ProgressView().tint(Theme.accent); Spacer() }
                        }
                    }

                    ForEach(store.products, id: \.id) { p in
                        planCard(p)
                    }

                    if let error { ErrorBanner(message: error) }

                    PrimaryButton(title: "Continue", loading: store.purchasing) {
                        Task { await buy() }
                    }
                    .disabled(selectedProduct == nil)

                    Text("Renews automatically until you cancel. Cancel any time in Settings → Manage subscription — it takes one tap.")
                        .font(Theme.Font.caption).foregroundStyle(Theme.textMuted)

                    HStack {
                        Button("Restore") { Task { await store.restore(); await app.refreshQuota(); if app.isPro { dismiss() } } }
                        Spacer()
                        Link("Terms", destination: Config.termsURL)
                        Spacer()
                        Link("Privacy", destination: Config.privacyURL)
                    }
                    .font(Theme.Font.caption)
                    .padding(.bottom, Theme.Space.xl)
                }
                .padding(Theme.Space.xl)
            }

            Button { dismiss() } label: {
                Text("Not now")
                    .font(Theme.Font.footnote.weight(.semibold))
                    .padding(.horizontal, 14).frame(minHeight: 36)
                    .foregroundStyle(Theme.text)
                    .background(Theme.surface2, in: Capsule())
            }
            .padding(Theme.Space.l)
            .accessibilityLabel("Close")
        }
        .background(Theme.bg.ignoresSafeArea())
        .task {
            if store.products.isEmpty { await store.loadProducts() }
            if selected == nil { selected = store.products.last?.id }
        }
        .onChange(of: store.products) { _, products in
            if selected == nil { selected = products.last?.id }
        }
    }

    private var selectedProduct: Product? { store.products.first { $0.id == selected } }

    private func planCard(_ p: Product) -> some View {
        let isOn = selected == p.id
        let isYear = p.subscription?.subscriptionPeriod.unit == .year
        return Button { selected = p.id } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Space.s) {
                        Text(store.label(for: p)).font(Theme.Font.headline).foregroundStyle(Theme.text)
                        if isYear {
                            Text("BEST VALUE").font(Theme.Font.caption).foregroundStyle(Theme.onAccent)
                                .padding(.horizontal, 6).padding(.vertical, 2).background(Theme.accent, in: Capsule())
                        }
                    }
                    if let perMonth = store.perMonth(p) {
                        Text(perMonth).font(Theme.Font.caption).foregroundStyle(Theme.textMuted)
                    }
                    if let intro = p.subscription?.introductoryOffer, intro.paymentMode == .freeTrial {
                        Text("\(intro.period.value)-\(unitName(intro.period.unit)) free trial, then \(p.displayPrice)")
                            .font(Theme.Font.caption).foregroundStyle(Theme.textMuted)
                    }
                }
                Spacer()
                Text(p.displayPrice).font(Theme.Font.headline).foregroundStyle(Theme.text)
            }
            .padding(Theme.Space.l)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).stroke(isOn ? Theme.accent : Theme.border, lineWidth: isOn ? 2 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func unitName(_ u: Product.SubscriptionPeriod.Unit) -> String {
        switch u {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "period"
        }
    }

    @MainActor
    private func buy() async {
        guard let p = selectedProduct else { return }
        error = nil
        do {
            if try await store.purchase(p) {
                await app.refreshQuota()
                dismiss()
            }
        } catch {
            self.error = "Purchase didn't go through. Try again?"
        }
    }
}
