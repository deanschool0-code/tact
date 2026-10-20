import SwiftData
import SwiftUI

/// S11: score your bio and get rewrites that keep your real facts.
struct BioView: View {
    @State private var bio = ""
    @State private var result: BioResult?
    @State private var loading = false
    @State private var error: String?
    @EnvironmentObject private var app: AppState
    @Environment(\.modelContext) private var context

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                TextBox(placeholder: "Paste your dating bio and prompt answers…", text: $bio, minHeight: 150)
                PrimaryButton(title: result == nil ? "Review my bio" : "Review again", systemImage: "person.text.rectangle", loading: loading) {
                    Task { await run() }
                }
                .disabled(bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let error { ErrorBanner(message: error) }

                if let r = result {
                    HStack { Spacer(); MeterView(value: r.score, label: "score"); Spacer() }
                    Text(r.summary).font(Theme.Font.body).foregroundStyle(Theme.text)
                    list("Working", r.strengths, "checkmark.circle.fill", Theme.success)
                    list("Fix", r.fixes, "arrow.up.circle.fill", Theme.warning)
                    SectionTitle(text: "Rewrites")
                    ForEach(r.rewrites) { ReplyCard(option: $0) }
                }
            }
            .padding(Theme.Space.l)
        }
        .scrollDismissesKeyboard(.interactively)
        .screen()
        .navigationTitle("Fix my bio")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func list(_ title: String, _ items: [String], _ icon: String, _ color: Color) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                SectionTitle(text: title)
                ForEach(items, id: \.self) { InfoLine(systemImage: icon, text: $0, color: color) }
            }
            .card()
        }
    }

    @MainActor
    private func run() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let (r, q) = try await APIClient.shared.generate(GenerateRequest(kind: .bio, text: bio), as: BioResult.self)
            withAnimation { result = r }
            app.quota = q
            app.remember(kind: .bio, title: "Bio \(r.score)/100", outputs: r.rewrites.map(\.text), in: context)
        } catch {
            self.error = app.message(for: error)
        }
    }
}
