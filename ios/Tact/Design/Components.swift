import SwiftUI
import UIKit

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, ghost }
    var kind: Kind = .primary
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Font.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(foreground)
            .background(background, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .primary: return Theme.onAccent
        case .secondary: return Theme.text
        case .ghost: return Theme.accent
        }
    }

    private var background: Color {
        switch kind {
        case .primary: return Theme.accent
        case .secondary: return Theme.surface2
        case .ghost: return .clear
        }
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var kind: PrimaryButtonStyle.Kind = .primary
    var loading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Space.s) {
                if loading {
                    ProgressView().tint(kind == .primary ? Theme.onAccent : Theme.text)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
        }
        .buttonStyle(PrimaryButtonStyle(kind: kind))
        .disabled(loading)
        .accessibilityLabel(title)
    }
}

// MARK: - Chips

struct Chip: View {
    let title: String
    var systemImage: String? = nil
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            action()
        } label: {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage).font(.system(size: 13, weight: .semibold)) }
                Text(title).font(Theme.Font.footnote.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .foregroundStyle(isOn ? Theme.onAccent : Theme.text)
            .background(isOn ? Theme.accent : Theme.surface2, in: Capsule())
            .overlay(Capsule().stroke(isOn ? Color.clear : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Wrapping row of chips.
struct ChipFlow<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        FlowLayout(spacing: Theme.Space.s) {
            ForEach(items, id: \.self) { content($0) }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Cards

struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.Space.l
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }
}

extension View {
    func card(padding: CGFloat = Theme.Space.l) -> some View { modifier(CardModifier(padding: padding)) }

    /// Standard screen background.
    func screen() -> some View {
        self.background(Theme.bg.ignoresSafeArea())
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .scrollContentBackground(.hidden)
    }
}

struct ToolCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var large = false

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: systemImage)
                .font(.system(size: large ? 22 : 18, weight: .bold))
                .foregroundStyle(Theme.onAccent)
                .frame(width: large ? 52 : 42, height: large ? 52 : 42)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(large ? Theme.Font.title : Theme.Font.headline).foregroundStyle(Theme.text)
                Text(subtitle).font(Theme.Font.footnote).foregroundStyle(Theme.textMuted)
                    .lineLimit(2).multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(Theme.textMuted).font(.system(size: 14, weight: .semibold))
        }
        .card(padding: large ? Theme.Space.xl : Theme.Space.l)
        .contentShape(Rectangle())
    }
}

struct ReplyCard: View {
    let option: ReplyOption
    var onFavourite: (() -> Void)? = nil
    var isFavourite = false
    var onTweak: ((TweakKind) -> Void)? = nil
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(option.text)
                .font(Theme.Font.body.weight(.medium))
                .foregroundStyle(Theme.text)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            if !option.why.isEmpty {
                Text(option.why).font(Theme.Font.caption).foregroundStyle(Theme.textMuted)
            }
            HStack(spacing: Theme.Space.s) {
                Button {
                    UIPasteboard.general.string = option.text
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { withAnimation { copied = false } }
                } label: {
                    Label(copied ? "Copied — go send it" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(Theme.Font.footnote.weight(.semibold))
                        .padding(.horizontal, 12).frame(minHeight: 34)
                        .foregroundStyle(Theme.onAccent)
                        .background(Theme.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                if let onTweak {
                    Menu {
                        ForEach(TweakKind.allCases) { t in
                            Button(t.label, systemImage: t.systemImage) { onTweak(t) }
                        }
                    } label: {
                        Label("Tweak", systemImage: "slider.horizontal.3")
                            .font(Theme.Font.footnote.weight(.semibold))
                            .padding(.horizontal, 12).frame(minHeight: 34)
                            .foregroundStyle(Theme.text)
                            .background(Theme.surface2, in: Capsule())
                    }
                }
                Spacer()
                if let onFavourite {
                    Button(action: onFavourite) {
                        Image(systemName: isFavourite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavourite ? Theme.danger : Theme.textMuted)
                            .frame(width: 44, height: 34)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isFavourite ? "Remove from favourites" : "Add to favourites")
                }
            }
        }
        .card()
    }
}

struct SkeletonCard: View {
    @State private var pulse = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 6).frame(height: 14)
            RoundedRectangle(cornerRadius: 6).frame(width: 200, height: 14)
            RoundedRectangle(cornerRadius: 6).frame(width: 90, height: 10)
        }
        .foregroundStyle(Theme.surface2)
        .opacity(pulse ? 0.5 : 1)
        .card()
        .onAppear { withAnimation(.easeInOut(duration: 0.8).repeatForever()) { pulse = true } }
        .accessibilityLabel("Loading")
    }
}

struct CreditsPill: View {
    @EnvironmentObject private var app: AppState
    var body: some View {
        Group {
            if app.isPro {
                Label("Pro", systemImage: "infinity")
            } else if let left = app.quota?.remaining {
                Label("\(left) free left", systemImage: "sparkles")
            } else {
                Label("\(Config.freeDaily) free a day", systemImage: "sparkles")
            }
        }
        .font(Theme.Font.caption)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .foregroundStyle(app.isPro ? Theme.onAccent : Theme.text)
        .background(app.isPro ? Theme.accent : Theme.surface2, in: Capsule())
    }
}

struct MeterView: View {
    let value: Int
    var label: String = ""
    @State private var shown: Double = 0

    var body: some View {
        ZStack {
            Circle().stroke(Theme.surface2, lineWidth: 14)
            Circle()
                .trim(from: 0, to: shown / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(value)").font(Theme.Font.display).foregroundStyle(Theme.text)
                if !label.isEmpty { Text(label).font(Theme.Font.caption).foregroundStyle(Theme.textMuted) }
            }
        }
        .frame(width: 150, height: 150)
        .onAppear { withAnimation(.easeOut(duration: 0.9)) { shown = Double(value) } }
        .onChange(of: value) { _, new in withAnimation { shown = Double(new) } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(value) out of 100")
    }

    private var color: Color {
        value >= 66 ? Theme.success : value >= 40 ? Theme.warning : Theme.danger
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: Theme.Space.m) {
            Image(systemName: systemImage).font(.system(size: 40)).foregroundStyle(Theme.textMuted)
            Text(title).font(Theme.Font.headline).foregroundStyle(Theme.text)
            Text(message).font(Theme.Font.footnote).foregroundStyle(Theme.textMuted).multilineTextAlignment(.center)
        }
        .padding(Theme.Space.xxl)
        .frame(maxWidth: .infinity)
    }
}

struct ErrorBanner: View {
    let message: String
    var retry: (() -> Void)? = nil
    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.danger)
            Text(message).font(Theme.Font.footnote).foregroundStyle(Theme.text)
            Spacer()
            if let retry {
                Button("Retry", action: retry).font(Theme.Font.footnote.weight(.semibold)).foregroundStyle(Theme.accent)
            }
        }
        .card(padding: Theme.Space.m)
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Theme.Font.caption)
            .foregroundStyle(Theme.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

struct InfoLine: View {
    let systemImage: String
    let text: String
    var color: Color = Theme.textMuted
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.s) {
            Image(systemName: systemImage).foregroundStyle(color)
            Text(text).font(Theme.Font.footnote).foregroundStyle(Theme.text)
        }
    }
}

/// Multiline text box styled like the rest of the app.
struct TextBox: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder).foregroundStyle(Theme.textMuted).padding(.horizontal, 5).padding(.vertical, 8)
            }
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .foregroundStyle(Theme.text)
        }
        .font(Theme.Font.body)
        .padding(Theme.Space.s)
        .frame(minHeight: minHeight)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.borderInput, lineWidth: 1))
    }
}
