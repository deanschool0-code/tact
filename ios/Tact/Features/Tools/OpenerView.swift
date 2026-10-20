import PhotosUI
import SwiftUI
import UIKit

/// S08: first message from a profile screenshot or pasted bio.
struct OpenerView: View {
    @AppStorage(Pref.defaultTone) private var defaultTone = Tone.chill.rawValue
    @AppStorage(Pref.redact) private var redact = true
    @State private var profile = ""
    @State private var pick: PhotosPickerItem?
    @State private var reading = false
    @State private var error: String?
    @State private var tone: Tone = .chill
    @State private var goal: Goal = .keepGoing
    @State private var extra = ""
    @State private var go = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                Text("Add their profile — a screenshot or paste their bio and prompts. The more detail, the better the hook.")
                    .font(Theme.Font.footnote).foregroundStyle(Theme.textMuted)

                PhotosPicker(selection: $pick, matching: .images) {
                    Label(reading ? "Reading…" : "Use a profile screenshot", systemImage: "photo")
                }
                .buttonStyle(PrimaryButtonStyle(kind: .secondary))
                .disabled(reading)

                TextBox(placeholder: "e.g. \"Looking for: someone to try every empanada spot in Santiago with. Typical Sunday: climbing then a nap.\"",
                        text: $profile, minHeight: 140)

                if let error { ErrorBanner(message: error) }

                ToneGoalPicker(tone: $tone, goal: $goal, extra: $extra, showGoal: false)

                PrimaryButton(title: "Write openers", systemImage: "wand.and.stars") { go = true }
                    .disabled(profile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(Theme.Space.l)
        }
        .scrollDismissesKeyboard(.interactively)
        .screen()
        .navigationTitle("First message")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $go) {
            ResultsView(kind: .opener, lines: [], text: profile, tone: tone, goal: nil, extra: extra)
        }
        .onAppear { tone = Tone(rawValue: defaultTone) ?? .chill }
        .onChange(of: pick) { _, item in
            guard let item else { return }
            Task { await read(item) }
        }
    }

    @MainActor
    private func read(_ item: PhotosPickerItem) async {
        reading = true
        error = nil
        defer { reading = false; pick = nil }
        do {
            guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                throw OCRService.OCRError.noImage
            }
            let text = try await OCRService.readText(from: image)
            let clean = redact ? Redactor.redact(text) : text
            profile = profile.isEmpty ? clean : profile + "\n" + clean
        } catch {
            self.error = error.localizedDescription
        }
    }
}
