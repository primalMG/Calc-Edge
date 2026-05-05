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
        }
    }
}
#endif
