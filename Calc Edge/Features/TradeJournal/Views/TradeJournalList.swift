//
//  TradeJournalList.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

#if os(iOS)
import SwiftUI

struct TradeJournalList: View {
    let trades: [Trade]
    let deleteItems: (IndexSet) -> Void
    let canLoadMore: Bool
    let loadMore: () -> Void

    var body: some View {
        List {
            ForEach(trades) { trade in
                NavigationLink {
                    TradeJournalDetailView(trade: trade)
                } label: {
                    TradeJournalRow(trade: trade)
                }
            }
            .onDelete(perform: deleteItems)

            PagedLoadMoreFooter(
                visibleCount: trades.count,
                canLoadMore: canLoadMore,
                loadMore: loadMore
            )
        }
    }
}
#endif
