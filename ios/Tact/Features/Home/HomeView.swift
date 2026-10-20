import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                HStack {
                    Text("tact").font(Theme.Font.display).foregroundStyle(Theme.text)
                    Spacer()
                    Button { if !app.isPro { app.showPaywall = true } } label: { CreditsPill() }
                        .buttonStyle(.plain)
                        .accessibilityLabel(app.isPro ? "Pro plan" : "Free replies left, see plans")
                }
                .padding(.top, Theme.Space.s)

                NavigationLink { ReplyFlowView() } label: {
                    ToolCard(title: "Reply to a chat",
                             subtitle: "Add a screenshot, pick a vibe, get replies that sound like you.",
                             systemImage: ToolKind.reply.systemImage, large: true)
                }
                .buttonStyle(.plain)

                SectionTitle(text: "More tools")

                NavigationLink { OpenerView() } label: {
                    ToolCard(title: "First message", subtitle: "From their profile or bio", systemImage: ToolKind.opener.systemImage)
                }
                .buttonStyle(.plain)

                NavigationLink { VibeCheckView() } label: {
                    ToolCard(title: "Vibe check", subtitle: "Are they into it? Honest read + next move", systemImage: ToolKind.vibe.systemImage)
                }
                .buttonStyle(.plain)

                NavigationLink { LinesView() } label: {
                    ToolCard(title: "Pickup lines", subtitle: "Cheesy on purpose — for a name or topic", systemImage: ToolKind.lines.systemImage)
                }
                .buttonStyle(.plain)

                NavigationLink { BioView() } label: {
                    ToolCard(title: "Fix my bio", subtitle: "Score + rewrites that keep your facts", systemImage: ToolKind.bio.systemImage)
                }
                .buttonStyle(.plain)

                if !app.isPro {
                    Text("\(Config.freeDaily) free every day across all tools. Resets at midnight UTC.")
                        .font(Theme.Font.caption).foregroundStyle(Theme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.Space.s)
                }
            }
            .padding(Theme.Space.l)
        }
        .screen()
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await app.refreshQuota() }
    }
}
