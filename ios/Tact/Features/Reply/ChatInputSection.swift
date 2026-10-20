import PhotosUI
import SwiftUI
import UIKit

/// Screenshot import + on-device OCR + editable bubbles + typing/paste fallback. Used by Reply and Vibe check.
struct ChatInputSection: View {
    @Binding var lines: [ChatLine]
    @AppStorage(Pref.redact) private var redact = true

    @State private var picks: [PhotosPickerItem] = []
    @State private var reading = false
    @State private var error: String?
    @State private var draft = ""
    @State private var draftSide: Side = .them
    @State private var editing: ChatLine?
    @State private var editText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            if lines.isEmpty && !reading {
                PhotosPicker(selection: $picks, maxSelectionCount: 3, matching: .images) {
                    VStack(spacing: Theme.Space.m) {
                        Image(systemName: "photo.badge.plus").font(.system(size: 34)).foregroundStyle(Theme.accent)
                        Text("Add chat screenshots").font(Theme.Font.headline).foregroundStyle(Theme.text)
                        Text("Up to 3, in order. Read on your phone — the image is never uploaded.")
                            .font(Theme.Font.footnote).foregroundStyle(Theme.textMuted).multilineTextAlignment(.center)
                    }
                    .padding(Theme.Space.xl)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.borderInput, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
                }
                .buttonStyle(.plain)
            }

            if reading {
                HStack(spacing: Theme.Space.m) {
                    ProgressView().tint(Theme.accent)
                    Text("Reading your screenshot…").font(Theme.Font.footnote).foregroundStyle(Theme.textMuted)
                }
                .card()
            }

            if let error { ErrorBanner(message: error) }

            if !lines.isEmpty {
                HStack {
                    SectionTitle(text: "The chat")
                    Spacer()
                    PhotosPicker(selection: $picks, maxSelectionCount: 3, matching: .images) {
                        Label("Add more", systemImage: "plus").font(Theme.Font.caption)
                    }
                    Button("Clear", role: .destructive) { withAnimation { lines.removeAll() } }
                        .font(Theme.Font.caption).padding(.leading, Theme.Space.s)
                }
                VStack(spacing: 6) {
                    ForEach(lines) { line in
                        bubble(line)
                    }
                }
                Text("Tap a bubble to switch who said it. Hold to edit or delete.")
                    .font(Theme.Font.caption).foregroundStyle(Theme.textMuted)
            }

            composer
        }
        .onChange(of: picks) { _, items in
            guard !items.isEmpty else { return }
            Task { await read(items) }
        }
        .alert("Edit message", isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })) {
            TextField("Message", text: $editText)
            Button("Save") {
                if let e = editing, let i = lines.firstIndex(where: { $0.id == e.id }) {
                    lines[i].text = editText
                }
                editing = nil
            }
            Button("Cancel", role: .cancel) { editing = nil }
        }
    }

    private func bubble(_ line: ChatLine) -> some View {
        HStack {
            if line.from == .me { Spacer(minLength: 48) }
            Text(line.text)
                .font(Theme.Font.body)
                .foregroundStyle(line.from == .me ? Theme.onBubbleMe : Theme.text)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(line.from == .me ? Theme.bubbleMe : Theme.bubbleThem,
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .onTapGesture {
                    if let i = lines.firstIndex(where: { $0.id == line.id }) {
                        withAnimation(.spring(response: 0.3)) { lines[i].from = line.from.flipped }
                    }
                }
                .contextMenu {
                    Button("Switch side", systemImage: "arrow.left.arrow.right") {
                        if let i = lines.firstIndex(where: { $0.id == line.id }) { lines[i].from = line.from.flipped }
                    }
                    Button("Edit", systemImage: "pencil") { editText = line.text; editing = line }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        lines.removeAll { $0.id == line.id }
                    }
                }
                .accessibilityLabel("\(line.from == .me ? "You" : "Them"): \(line.text)")
                .accessibilityHint("Double tap to switch who said it")
            if line.from == .them { Spacer(minLength: 48) }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack(spacing: Theme.Space.s) {
                Picker("Who", selection: $draftSide) {
                    Text("Them").tag(Side.them)
                    Text("Me").tag(Side.me)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
                TextField(lines.isEmpty ? "Or type what they said…" : "Add a message…", text: $draft)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12).frame(minHeight: 40)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.sm).stroke(Theme.borderInput, lineWidth: 1))
                    .submitLabel(.done)
                    .onSubmit(addDraft)
                Button(action: addDraft) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 28)).foregroundStyle(Theme.accent)
                }
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add message")
            }
            PasteButton(payloadType: String.self) { strings in
                let parsed = Self.parsePasted(strings.joined(separator: "\n"))
                Task { @MainActor in
                    lines.append(contentsOf: redact ? Redactor.redact(parsed) : parsed)
                }
            }
            .labelStyle(.titleAndIcon)
            .tint(Theme.surface2)
            .font(Theme.Font.caption)
        }
    }

    private func addDraft() {
        let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        lines.append(ChatLine(from: draftSide, text: redact ? Redactor.redact(t) : t))
        draft = ""
        draftSide = draftSide.flipped
    }

    /// "me: ..." / "yo: ..." lines are mine; everything else is theirs.
    static func parsePasted(_ text: String) -> [ChatLine] {
        text.split(whereSeparator: \.isNewline).compactMap { raw -> ChatLine? in
            let s = raw.trimmingCharacters(in: .whitespaces)
            guard !s.isEmpty else { return nil }
            for prefix in ["me:", "yo:", "me -", "you:"] where s.lowercased().hasPrefix(prefix) {
                return ChatLine(from: .me, text: String(s.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces))
            }
            for prefix in ["them:", "her:", "him:", "ella:", "él:", "el:"] where s.lowercased().hasPrefix(prefix) {
                return ChatLine(from: .them, text: String(s.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces))
            }
            return ChatLine(from: .them, text: s)
        }
    }

    @MainActor
    private func read(_ items: [PhotosPickerItem]) async {
        reading = true
        error = nil
        defer { reading = false; picks = [] }
        var found: [ChatLine] = []
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { throw OCRService.OCRError.noImage }
                found += try await OCRService.readChat(from: image)
            } catch {
                self.error = error.localizedDescription
            }
        }
        if !found.isEmpty { error = nil }
        withAnimation { lines += redact ? Redactor.redact(found) : found }
    }
}
