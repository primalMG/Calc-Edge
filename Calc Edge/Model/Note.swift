//
//  Note.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 07/05/2026.
//

import Foundation
import SwiftData

@Model
final class Note {
    var noteId: UUID = UUID()
    var title: String = ""
    @Attribute(.externalStorage) var body: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    init(
        noteId: UUID = UUID(),
        title: String = "",
        body: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.noteId = noteId
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
