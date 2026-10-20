import SwiftData
import SwiftUI

/// S07: reply options for reply / opener / lines, with tone switching, tweaks and favourites.
struct ResultsView: View {
    let kind: ToolKind
    let lines: [ChatLine]
    let text: String
    let goal: Goal?
    let extra: String

    @State private var tone: Tone
    @State private var result: ReplyResult?
    @State private var loading = false
    @State private var error: String?
    @State private var tweaks: [String: [ReplyOption]] = [:]
    @State private var tweaking: String?
    @State private var favourites: [String: Generation] = [:]

    @EnvironmentObject private var app: AppState
    @Environment(\.modelContext) private var context

    init(kind: ToolKind, lines: [ChatLine], text: String, tone: Tone, goal: Goal?, extra: String) {
        self.kind = kind
        self.lines = lines
        self.text = text
        self.goal = goal
        self.extra = extra
        _tone = State(initialValue: tone)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.s) {
                        ForEach(Tone.allCases) { t in
                            Chip(title: t.label, systemImage: t.systemImage, isOn: tone == t) {
                                guard tone != t, !loading else { return }
                                tone = t
                                Task { await generate() }
                            }
                        }
                    }
                }

                if let read = result?.read, !read.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionTitle(text: "The read")
                        Text(read).font(Theme.Font.footnote).foregroundStyle(Theme.text)
                    }
                    .card(padding: Theme.Space.m)
                }

                if result?.boundary == true {
                    InfoLine(systemImage: "hand.raised.fill",
                             text: "Heads up: they might not be into this right now. These keep it respectful — no pushing.",
                             color: Theme.warning)
                        .card(padding: Theme.Space.m)
                }

                if let error {
                    ErrorBanner(message: error) { Task { await generate() } }
                }

                if loading && result == nil {
                    ForEach(0..<4, id: \.self) { _ in SkeletonCard() }
                }

                ForEach(result?.replies ?? []) { option in
                    ReplyCard(option: option,
                              onFavourite: { toggleFavourite(option) },
                              isFavourite: favourites[option.id] != nil,
                              onTweak: kind == .lines ? nil : tweakAction(for: option))
                    if tweaking == option.id {
                        HStack { ProgressView().tint(Theme.accent); Text("Tweaking…").font(Theme.Font.caption).foregroundStyle(Theme.textMuted) }
                            .padding(.leading, Theme.Space.l)
                    }
                    ForEach(tweaks[option.id] ?? []) { alt in
                        ReplyCard(option: alt, onFavourite: { toggleFavourite(alt) }, isFavourite: favourites[alt.id] != nil)
                            .padding(.leading, Theme.Space.xl)
                    }
                }

                if result != nil {
                    PrimaryButton(title: "More options", systemImage: "arrow.clockwise", kind: .secondary, loading: loading) {
                        Task { await generate() }
                    }
                    .padding(.top, Theme.Space.s)
                }
            }
            .padding(Theme.Space.l)
        }
        .screen()
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { CreditsPill() } }
        .task { if result == nil && !loading { await generate() } }
    }

    private var historyTitle: String {
        switch kind {
        case .reply: return lines.last(where: { $0.from == .them })?.text ?? "Reply"
        case .opener: return "Opener: \(text.prefix(60))"
        case .lines: return text.isEmpty ? "Pickup lines" : "Lines: \(text)"
        default: return kind.title
        }
    }

    @MainActor
    private func generate() async {
        loading = true
        error = nil
        defer { loading = false }
        let req = GenerateRequest(kind: kind, lines: lines, text: text, tone: tone, goal: goal, extra: extra)
        do {
            let (r, q) = try await APIClient.shared.generate(req, as: ReplyResult.self)
            withAnimation { result = r }
            tweaks = [:]
            app.quota = q
            app.remember(kind: kind, title: String(historyTitle.prefix(80)), outputs: r.replies.map(\.text),
                         note: r.read ?? "", in: context)
        } catch {
            self.error = app.message(for: error)
        }
    }

    private func tweakAction(for option: ReplyOption) -> (TweakKind) -> Void {
        { how in Task { await tweak(option, how) } }
    }

    @MainActor
    private func tweak(_ option: ReplyOption, _ how: TweakKind) async {
        tweaking = option.id
        defer { tweaking = nil }
        let req = GenerateRequest(kind: .tweak, lines: lines, tweak: how, base: option.text)
        do {
            let (r, q) = try await APIClient.shared.generate(req, as: ReplyResult.self)
            withAnimation { tweaks[option.id] = r.replies }
            app.quota = q
            SharedReplies.add(r.replies.map(\.text))
        } catch {
            self.error = app.message(for: error)
        }
    }

    private func toggleFavourite(_ option: ReplyOption) {
        if let g = favourites[option.id] {
            context.delete(g)
            favourites[option.id] = nil
        } else {
            let g = Generation(kind: kind, title: String(historyTitle.prefix(80)), outputs: [option.text], favourite: true)
            context.insert(g)
            favourites[option.id] = g
        }
        try? context.save()
    }
}
