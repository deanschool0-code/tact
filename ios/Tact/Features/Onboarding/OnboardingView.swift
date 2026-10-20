import SwiftUI

struct OnboardingView: View {
    @AppStorage(Pref.onboarded) private var onboarded = false
    @AppStorage(Pref.ageConfirmed) private var ageConfirmed = false
    @AppStorage(Pref.style) private var style = ""
    @AppStorage(Pref.defaultTone) private var defaultTone = Tone.chill.rawValue
    @AppStorage(Pref.voiceSamples) private var voiceSamples = ""
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(page + 1), total: 4)
                .tint(Theme.accent)
                .padding(.horizontal, Theme.Space.xl)
                .padding(.top, Theme.Space.m)
                .accessibilityLabel("Step \(page + 1) of 4")

            TabView(selection: $page) {
                welcome.tag(0)
                stylePage.tag(1)
                voicePage.tag(2)
                agePage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    // MARK: pages

    private var welcome: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xl) {
            Spacer()
            Image(systemName: "checkmark.bubble.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Say the right thing.")
                .font(Theme.Font.display).foregroundStyle(Theme.text)
            Text("Drop in a screenshot of your chat. Tact writes replies that sound like you — about what they actually said.")
                .font(Theme.Font.body).foregroundStyle(Theme.textMuted)
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                InfoLine(systemImage: "lock.fill", text: "Screenshots are read on your iPhone. Only the text is sent.", color: Theme.accent)
                InfoLine(systemImage: "gift.fill", text: "\(Config.freeDaily) free replies every day. No card needed.", color: Theme.accent)
                InfoLine(systemImage: "hand.raised.fill", text: "No cheesy lines unless you ask for them.", color: Theme.accent)
            }
            Spacer()
            PrimaryButton(title: "Let's go") { page = 1 }
        }
        .padding(Theme.Space.xl)
    }

    private var stylePage: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xl) {
            Spacer()
            Text("How do you usually text?").font(Theme.Font.title).foregroundStyle(Theme.text)
            VStack(spacing: Theme.Space.m) {
                ForEach(Style.allCases) { s in
                    Button {
                        style = s.rawValue
                        defaultTone = (s == .funny ? Tone.funny : s == .bold ? .bold : s == .sweet ? .sweet : .chill).rawValue
                    } label: {
                        HStack {
                            Text(s.label).font(Theme.Font.headline).foregroundStyle(Theme.text)
                            Spacer()
                            Image(systemName: style == s.rawValue ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(style == s.rawValue ? Theme.accent : Theme.textMuted)
                        }
                        .card()
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(style == s.rawValue ? .isSelected : [])
                }
            }
            Spacer()
            PrimaryButton(title: "Next") { page = 2 }.disabled(style.isEmpty)
        }
        .padding(Theme.Space.xl)
    }

    private var voicePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                Text("Teach it your voice").font(Theme.Font.title).foregroundStyle(Theme.text).padding(.top, Theme.Space.xl)
                Text("Paste 3–5 texts you've actually sent — one per line. Tact copies your length, slang and emoji habits, not the words.")
                    .font(Theme.Font.body).foregroundStyle(Theme.textMuted)
                TextBox(placeholder: "haha no way\nok but hear me out\nwe should go this weekend fr", text: $voiceSamples, minHeight: 160)
                Text("Stays on your phone. Sent only as style hints when you generate.")
                    .font(Theme.Font.caption).foregroundStyle(Theme.textMuted)
                PrimaryButton(title: voiceSamples.isEmpty ? "Skip for now" : "Next", kind: voiceSamples.isEmpty ? .secondary : .primary) {
                    page = 3
                }
                .padding(.top, Theme.Space.l)
            }
            .padding(Theme.Space.xl)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var agePage: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xl) {
            Spacer()
            Text("One last thing").font(Theme.Font.title).foregroundStyle(Theme.text)
            Text("Tact is for adults dating adults. It won't write anything explicit, and it'll tell you when someone isn't into it.")
                .font(Theme.Font.body).foregroundStyle(Theme.textMuted)
            Toggle(isOn: $ageConfirmed) {
                Text("I'm 18 or older").font(Theme.Font.headline).foregroundStyle(Theme.text)
            }
            .tint(Theme.accent)
            .card()
            Spacer()
            PrimaryButton(title: "Start using Tact") { onboarded = true }
                .disabled(!ageConfirmed)
        }
        .padding(Theme.Space.xl)
    }
}
