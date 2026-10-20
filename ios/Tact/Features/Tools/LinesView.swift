import SwiftUI

/// S09: pickup lines for a name or topic. The one place cheesy is the point.
struct LinesView: View {
    @State private var topic = ""
    @State private var tone: Tone = .funny
    @State private var go = false

    private let ideas = ["Coffee", "Gym", "Music", "Travel", "Dogs", "Food", "Books", "Hiking", "Gaming", "Art"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                TextField("A name or a topic (optional)", text: $topic)
                    .padding(14)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.borderInput, lineWidth: 1))
                    .submitLabel(.go)
                    .onSubmit { go = true }

                SectionTitle(text: "Ideas")
                ChipFlow(items: ideas) { idea in
                    Chip(title: idea, isOn: topic == idea) { topic = (topic == idea ? "" : idea) }
                }

                SectionTitle(text: "Vibe")
                ChipFlow(items: [Tone.funny, .witty, .flirty, .sweet]) { t in
                    Chip(title: t.label, systemImage: t.systemImage, isOn: tone == t) { tone = t }
                }

                InfoLine(systemImage: "info.circle", text: "Lines are for fun openers. For a real conversation, use Reply — it reads the chat.")

                PrimaryButton(title: "Give me lines", systemImage: "sparkles") { go = true }
            }
            .padding(Theme.Space.l)
        }
        .screen()
        .navigationTitle("Pickup lines")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $go) {
            ResultsView(kind: .lines, lines: [], text: topic, tone: tone, goal: nil, extra: "")
        }
    }
}
