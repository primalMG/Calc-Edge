//
//  DirectionFilter.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import Foundation

enum DirectionFilter: String, CaseIterable, Identifiable {
    case all
    case long
    case short

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Directions"
        case .long:
            return "Long"
        case .short:
            return "Short"
        }
    }

    func matches(_ direction: TradeDirection) -> Bool {
        switch self {
        case .all:
            return true
        case .long:
            return direction == .long
        case .short:
            return direction == .short
        }
    }
}
