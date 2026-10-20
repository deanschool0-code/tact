import SwiftUI
import UIKit

/// S15 — the Tact keyboard: tap a saved reply to insert it into any app.
final class KeyboardViewController: UIInputViewController {
    private var host: UIHostingController<KeyboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        let view = KeyboardView(
            replies: hasFullAccess ? SharedReplies.load() : [],
            hasFullAccess: hasFullAccess,
            showsGlobe: needsInputModeSwitchKey,
            insert: { [weak self] text in self?.textDocumentProxy.insertText(text) },
            deleteBackward: { [weak self] in self?.textDocumentProxy.deleteBackward() },
            nextKeyboard: { [weak self] in self?.advanceToNextInputMode() },
            space: { [weak self] in self?.textDocumentProxy.insertText(" ") },
            returnKey: { [weak self] in self?.textDocumentProxy.insertText("\n") }
        )
        let hosting = UIHostingController(rootView: view)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hosting)
        self.view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])
        let height = hosting.view.heightAnchor.constraint(equalToConstant: 260)
        height.priority = UILayoutPriority(999)
        height.isActive = true
        hosting.didMove(toParent: self)
        host = hosting
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        host?.rootView.replies = hasFullAccess ? SharedReplies.load() : []
    }
}

struct KeyboardView: View {
    var replies: [String]
    let hasFullAccess: Bool
    let showsGlobe: Bool
    let insert: (String) -> Void
    let deleteBackward: () -> Void
    let nextKeyboard: () -> Void
    let space: () -> Void
    let returnKey: () -> Void

    private let ink = Color(red: 0.05, green: 0.06, blue: 0.08)
    private let card = Color(red: 0.12, green: 0.14, blue: 0.19)
    private let lime = Color(red: 0.78, green: 0.95, blue: 0.35)

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("tact").font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(lime)
                Spacer()
                Text(replies.isEmpty ? "" : "Tap to insert").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if !hasFullAccess {
                message("Turn on Allow Full Access for Tact in Settings → General → Keyboard → Keyboards to see your replies.")
            } else if replies.isEmpty {
                message("No replies yet. Write some in the Tact app and they'll show up here.")
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(replies, id: \.self) { r in
                            Button { insert(r) } label: {
                                Text(r)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12).padding(.vertical, 9)
                                    .background(card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }

            HStack(spacing: 6) {
                if showsGlobe {
                    key(systemImage: "globe", action: nextKeyboard).frame(width: 48)
                }
                key(title: "space", action: space)
                key(systemImage: "delete.left", action: deleteBackward).frame(width: 56)
                key(systemImage: "return", action: returnKey).frame(width: 56)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ink)
        .environment(\.colorScheme, .dark)
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func key(title: String? = nil, systemImage: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let systemImage { Image(systemName: systemImage) } else { Text(title ?? "") }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(card, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title ?? systemImage ?? "key")
    }
}
