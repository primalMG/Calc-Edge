//
//  JournalPresentation.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import Foundation

enum JournalPresentation: Identifiable {
    case draft(JournalDraftPresentation)
    case importReview(JournalImportReviewPresentation)

    var id: UUID {
        switch self {
        case .draft(let draft):
            draft.id
        case .importReview(let importReview):
            importReview.id
        }
    }
}

struct JournalDraftPresentation: Identifiable {
    let id = UUID()
    let trade: Trade
}

struct JournalImportReviewPresentation: Identifiable {
    let id = UUID()
    let trades: [Trade]
}
