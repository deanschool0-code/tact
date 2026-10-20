import SwiftData
import SwiftUI

/// S13: everything you generated, on this phone only.
struct HistoryView: View {
    @Query(sort: \Generation.createdAt, order: .reverse) private var all: [Generation]
    @Environment(\.modelContext) private var context
    @State private var favouritesOnly = false
    @State private var search = ""

    private var items: [Generation] {
        all.filter { g in
            (!favouritesOnly || g.favourite) &&
            (search.isEmpty || g.title.localizedCaseInsensitiveContains(search)
                || g.outputs.contains { $0.localizedCaseInsensitiveContains(search) })
        }
    }

    var body: some View {
        List {
            Picker("Show", selection: $favouritesOnly) {
                Text("All").tag(false)
                Text("Favourites").tag(true)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            if items.isEmpty {
                EmptyStateView(systemImage: favouritesOnly ? "heart" : "clock",
                               title: favouritesOnly ? "No favourites yet" : "Nothing yet",
                               message: favouritesOnly ? "Tap the heart on a reply to keep it here."
                                                       : "Your best replies will live here.")
                    .listRowBackground(Color.clear)
            }

            ForEach(items) { g in
                NavigationLink { HistoryDetail(item: g) } label: {
                    HStack(spacing: Theme.Space.m) {
                        Image(systemName: g.favourite ? "heart.fill" : g.kind.systemImage)
                            .foregroundStyle(g.favourite ? Theme.danger : Theme.accent)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(g.title).font(Theme.Font.footnote.weight(.semibold)).foregroundStyle(Theme.text).lineLimit(1)
                            Text(g.outputs.first ?? "").font(Theme.Font.caption).foregroundStyle(Theme.textMuted).lineLimit(1)
                        }
                        Spacer()
                        Text(g.createdAt, style: .relative).font(Theme.Font.caption).foregroundStyle(Theme.textMuted)
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .onDelete { idx in
                for i in idx { context.delete(items[i]) }
                try? context.save()
            }
        }
        .searchable(text: $search, prompt: "Search saved replies")
        .screen()
        .navigationTitle("Saved")
    }
}

struct HistoryDetail: View {
    @Bindable var item: Generation

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                Text(item.title).font(Theme.Font.headline).foregroundStyle(Theme.text)
                if !item.note.isEmpty {
                    Text(item.note).font(Theme.Font.footnote).foregroundStyle(Theme.textMuted)
                }
                ForEach(item.outputs, id: \.self) { ReplyCard(option: ReplyOption(text: $0)) }
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.Font.caption).foregroundStyle(Theme.textMuted)
            }
            .padding(Theme.Space.l)
        }
        .screen()
        .navigationTitle(item.kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { item.favourite.toggle() } label: {
                    Image(systemName: item.favourite ? "heart.fill" : "heart")
                }
                .accessibilityLabel(item.favourite ? "Unfavourite" : "Favourite")
            }
        }
    }
}
