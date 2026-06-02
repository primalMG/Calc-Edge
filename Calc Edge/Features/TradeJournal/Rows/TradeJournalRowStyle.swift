//
//  TradeJournalRowStyle.swift
//  Calc Edge
//
//  Created by Codex on 30/05/2026.
//

#if os(iOS)
import SwiftUI

extension InstrumentType {
    var journalColor: Color {
        switch self {
        case .stock:
            return .blue
        case .etf:
            return .teal
        case .option:
            return .purple
        case .future:
            return .orange
        case .forex:
            return .indigo
        case .crypto:
            return .yellow
        case .cfd:
            return .pink
        case .other:
            return .secondary
        }
    }

    var journalSystemImage: String {
        switch self {
        case .stock:
            return "chart.line.uptrend.xyaxis"
        case .etf:
            return "chart.pie.fill"
        case .option:
            return "slider.horizontal.3"
        case .future:
            return "calendar.badge.clock"
        case .forex:
            return "coloncurrencysign.circle.fill"
        case .crypto:
            return "bitcoinsign.circle.fill"
        case .cfd:
            return "plus.forwardslash.minus"
        case .other:
            return "tag.fill"
        }
    }
}

extension String {
    var journalAccountColor: Color {
        let palette: [Color] = [.blue, .green, .orange, .purple, .teal, .pink]
        let index = Int(deterministicJournalHash % UInt64(palette.count))
        return palette[index]
    }

    private var deterministicJournalHash: UInt64 {
        unicodeScalars.reduce(5381) { hash, scalar in
            ((hash << 5) &+ hash) &+ UInt64(scalar.value)
        }
    }
}
#endif
