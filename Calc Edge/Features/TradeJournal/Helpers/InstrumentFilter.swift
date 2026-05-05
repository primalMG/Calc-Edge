//
//  InstrumentFilter.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import Foundation

enum InstrumentFilter: String, CaseIterable, Identifiable {
    case all
    case stock
    case etf
    case option
    case future
    case forex
    case crypto
    case cfd
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Instruments"
        case .stock:
            return "Stock"
        case .etf:
            return "ETF"
        case .option:
            return "Option"
        case .future:
            return "Future"
        case .forex:
            return "Forex"
        case .crypto:
            return "Crypto"
        case .cfd:
            return "CFD"
        case .other:
            return "Other"
        }
    }

    func matches(_ instrument: InstrumentType) -> Bool {
        switch self {
        case .all:
            return true
        case .stock:
            return instrument == .stock
        case .etf:
            return instrument == .etf
        case .option:
            return instrument == .option
        case .future:
            return instrument == .future
        case .forex:
            return instrument == .forex
        case .crypto:
            return instrument == .crypto
        case .cfd:
            return instrument == .cfd
        case .other:
            return instrument == .other
        }
    }
}
