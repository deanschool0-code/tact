import StoreKit
import SwiftData
import SwiftUI
import UIKit

/// S14
struct SettingsView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var store: Store
    @Environment(\.modelContext) private var context
    @AppStorage(Pref.defaultTone) private var defaultTone = Tone.chill.rawValue
    @AppStorage(Pref.redact) private var redact = true
    @AppStorage(Pref.serverURL) private var serverURL = ""
    @AppStorage(Pref.onboarded) private var onboarded = true
    @State private var manage = false
    @State private var confirmDelete = false
    @State private var deleted = false
    @State private var serverStatus: String?
    @State private var restoring = false

    var body: some View {
        Form {
            Section("Plan") {
                if app.isPro {
                    Label("Tact Pro — unlimited", systemImage: "infinity").foregroundStyle(Theme.accent)
                    Button("Manage or cancel subscription") { manage = true }
                } else {
                    HStack {
                        Text("Free")
                        Spacer()
                        Text("\(app.quota?.remaining ?? Config.freeDaily) of \(Config.freeDaily) left today")
                            .foregroundStyle(Theme.textMuted)
                    }
                    Button("See Pro") { app.showPaywall = true }
                }
                Button(restoring ? "Restoring…" : "Restore purchases") {
                    Task { restoring = true; await store.restore(); await app.refreshQuota(); restoring = false }
                }
                .disabled(restoring)
            }

            Section {
                NavigationLink("Your voice") { VoiceSetupView() }
                Picker("Default vibe", selection: $defaultTone) {
                    ForEach(Tone.allCases) { Text($0.label).tag($0.rawValue) }
                }
            } header: { Text("Sound like you") } footer: {
                Text("Your sample texts teach Tact your length, slang and emoji habits.")
            }

            Section("Keyboard") {
                NavigationLink("Set up the Tact keyboard") { KeyboardSetupView() }
            }

            Section {
                Toggle("Hide numbers, emails and links", isOn: $redact).tint(Theme.accent)
                Button("Delete all my data", role: .destructive) { confirmDelete = true }
            } header: { Text("Privacy") } footer: {
                Text("Screenshots are read on your iPhone and never uploaded. Only the chat text is sent to write replies, and it isn't stored on our server. History stays on this phone.")
            }

            Section {
                TextField(Config.defaultServerURL, text: $serverURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Test connection") {
                    Task {
                        serverStatus = "Checking…"
                        serverStatus = await APIClient.shared.health() ? "Connected ✓" : "Can't reach \(APIClient.shared.baseURL.absoluteString)"
                        await app.refreshQuota()
                    }
                }
                if let serverStatus { Text(serverStatus).font(Theme.Font.caption).foregroundStyle(Theme.textMuted) }
                Button("Replay onboarding") { onboarded = false }
            } header: { Text("Developer") } footer: {
                Text("Leave empty to use \(Config.defaultServerURL). On a real iPhone use your tunnel URL, e.g. https://tact.yourdomain.com")
            }

            Section("About") {
                Link("Privacy policy", destination: Config.privacyURL)
                Link("Terms of use", destination: Config.termsURL)
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .screen()
        .navigationTitle("Settings")
        .manageSubscriptionsSheet(isPresented: $manage)
        .confirmationDialog("Delete everything?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete my data", role: .destructive) { Task { await deleteAll() } }
        } message: {
            Text("Removes your history, favourites, voice samples and keyboard replies from this phone, and your usage record from our server. Your subscription stays active — cancel it in Manage subscription.")
        }
        .alert("Deleted", isPresented: $deleted) { Button("OK", role: .cancel) {} } message: {
            Text("Your data is gone.")
        }
    }

    @MainActor
    private func deleteAll() async {
        try? context.delete(model: Generation.self)
        try? context.save()
        SharedReplies.clear()
        UserDefaults.standard.removeObject(forKey: Pref.voiceSamples)
        try? await APIClient.shared.deleteServerData()
        await app.refreshQuota()
        deleted = true
    }
}

struct VoiceSetupView: View {
    @AppStorage(Pref.voiceSamples) private var voiceSamples = ""
    @AppStorage(Pref.style) private var style = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                Text("Paste 3–8 texts you've actually sent, one per line. The more \"you\" they are, the better.")
                    .font(Theme.Font.footnote).foregroundStyle(Theme.textMuted)
                TextBox(placeholder: "haha no way\nok but hear me out\nwe should go this weekend fr", text: $voiceSamples, minHeight: 200)
                Text("\(Pref.voice.count) samples").font(Theme.Font.caption).foregroundStyle(Theme.textMuted)
                SectionTitle(text: "How you text")
                ChipFlow(items: Style.allCases) { s in
                    Chip(title: s.label, isOn: style == s.rawValue) { style = s.rawValue }
                }
            }
            .padding(Theme.Space.l)
        }
        .scrollDismissesKeyboard(.interactively)
        .screen()
        .navigationTitle("Your voice")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// S16
struct KeyboardSetupView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                Text("Paste your replies straight into Hinge, Tinder, Instagram or iMessage — no switching apps.")
                    .font(Theme.Font.body).foregroundStyle(Theme.textMuted)
                step(1, "Open Settings → General → Keyboard → Keyboards → Add New Keyboard…")
                step(2, "Pick **Tact**.")
                step(3, "Tap Tact again and turn on **Allow Full Access** so it can see the replies you saved in the app. It doesn't send anything you type anywhere.")
                step(4, "In any chat, hold the 🌐 key and choose Tact. Tap a reply to drop it in.")
                PrimaryButton(title: "Open Settings", systemImage: "gear") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                .padding(.top, Theme.Space.m)
            }
            .padding(Theme.Space.l)
        }
        .screen()
        .navigationTitle("Keyboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func step(_ n: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: Theme.Space.m) {
            Text("\(n)").font(Theme.Font.headline).foregroundStyle(Theme.onAccent)
                .frame(width: 30, height: 30).background(Theme.accent, in: Circle())
            Text(text).font(Theme.Font.body).foregroundStyle(Theme.text)
        }
    }
}
