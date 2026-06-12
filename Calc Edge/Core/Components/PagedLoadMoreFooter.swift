import SwiftUI

enum PlatformPageSize {
    #if os(macOS)
    static let initial = 200
    static let increment = 200
    #else
    static let initial = 50
    static let increment = 50
    #endif
}

struct PagedLoadMoreFooter: View {
    let visibleCount: Int
    let canLoadMore: Bool
    let loadMore: () -> Void

    var body: some View {
        if canLoadMore {
            Button(action: loadMore) {
                Label("Load More", systemImage: "chevron.down.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            .padding(.vertical, 8)
            .help("Load more entries")
        } else if visibleCount > 0 {
            Text("Showing \(visibleCount) entries")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
    }
}
